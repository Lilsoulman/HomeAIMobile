# HomeMind 业务后端设计文档

> 本文档面向**后续写 .NET 后端代码的同事**，基于 `D:\HomeMind\core` 已搭好的 9 项目解决方案，按本文档的"实体 → 仓储 → 服务 → 控制器"骨架填充代码即可。
> 配套前端：`D:\HomeMind\mobile`，端点定义见 `PROJECT_PLAN.md §4.2`。
> 写作日期：2026-08-03；对应里程碑：M4（账号 + 同步） + M5（业务后端）。

---

## §1 架构总览

### 1.1 两套后端

| 后端 | 项目 | 职责 | 状态 |
|---|---|---|---|
| **AI 网关** | `D:\HomeMind\core\HomeMind.Api`（未来加 `AIController`） | 接收前端 `/api/v1/ai/generate`，用用户 Key 调 OpenAI 兼容 `/chat/completions`；Key 加密存 | M3 阶段 |
| **业务后端** | 新建 `D:\HomeMind\core\HomeMind.Business.Api`（独立 WebApi 项目，复用现有分层） | 账户 / Todo / 日历 / 订阅 / iCal 代理 / 天气代理 / 附件 / 同步 | M4~M5 |

> **命名说明**：本计划将当前 `HomeMind.Api` 视为"AI 网关+业务后端二合一"的 WebApi 入口（`/api/v1/ai/*` 给 AI，`/api/v1/todos` 等给业务）。如果你倾向拆为两个独立 WebApi 项目，可把 `HomeMind.Api` 改名为 `HomeMind.AIGateway`，新建 `HomeMind.Business.Api`。下文按"二合一"方案描述，二者路由前缀不同即可。

### 1.2 现有解决方案结构

```
HomeMind.Core.sln
├── HomeMind.Api                          [Web入口 .NET 8]     ← 注册服务、Swagger、JWT、CORS
├── HomeMind.Business.IServices           [业务接口]           ← IService 接口
├── HomeMind.Business.Services            [业务实现]           ← Service 实现
├── HomeMind.Common.Helpers               [工具类]             ← JwtHelper / BCryptHelper / EncryptionHelper
├── HomeMind.Common.IRepository           [仓储接口]           ← IRepository<T> 基础 + IXxxRepository
├── HomeMind.Common.IServices             [通用业务接口]        ← 预留（与 Business.IServices 区分）
├── HomeMind.Common.Infrastructure        [基础设施]           ← DbContext / DI 扩展
├── HomeMind.Common.Model                 [实体]               ← SqlSugar 实体类
└── HomeMind.Common.Repository            [仓储实现]           ← BaseRepository<T> + 仓储实现
```

### 1.3 调用关系图

```
┌──────────────┐
│ Mobile (H5)  │
└──────┬───────┘
       │ HTTPS /api/v1/*
       ▼
┌──────────────────────────────┐
│  HomeMind.Api (WebApi)       │  ← JwtBearer 中间件 + CORS
│  Controllers/*               │
└──┬──────────┬─────────┬──────┘
   │          │         │
   ▼          ▼         ▼
[IServices]  [Helpers]  [DbContext]
   │          │         │  SqlSugar
   ▼          ▼         ▼
[Services]  [JwtHelper]  [MySQL 8.0]
   │          │         ↑
   ▼          │         │
[Repository]──┴─────────┘
```

---

## §2 账户登录流程

### 2.1 技术选型

| 项 | 选型 | NuGet 包 | 版本 |
|---|---|---|---|
| JWT 生成与校验 | `Microsoft.AspNetCore.Authentication.JwtBearer` | `Microsoft.AspNetCore.Authentication.JwtBearer` | `8.0.*` |
| JWT Token 构造 | `System.IdentityModel.Tokens.Jwt` | `System.IdentityModel.Tokens.Jwt` | `7.*` |
| 密码哈希 | BCrypt | `BCrypt.Net-Next` | `4.0.3` |
| ORM | SqlSugar | `SqlSugarCore` | `5.1.*` |
| MySQL 驱动 | MySqlConnector | `MySqlConnector` | `2.3.*` |

### 2.2 JWT 设计

- **算法**：HS256（首版）；密钥 ≥ 32 字节，从 `appsettings.json:Jwt:Key` 读
- **Access Token**：15 分钟；claim 含 `sub(userId)` / `phone` / `iat` / `exp` / `jti`
- **Refresh Token**：7 天；随机 32 字节 → base64url；存 `refresh_tokens` 表（含 `user_id` / `token_hash` / `expires_at` / `revoked_at` / `created_at`）
- **旋转策略**：每次 `POST /auth/refresh` → 旧 token 标记 `revoked_at = NOW()` + 新 token 下发；旧 token 24 小时内仍可重试一次（防并发）

### 2.3 时序图

```
用户                     Mobile H5              HomeMind.Api           MySQL
 │                          │                       │                    │
 │ 1. 输入 phone + password │                       │                    │
 ├─────────────────────────►│                       │                    │
 │                          │ 2. POST /auth/login   │                    │
 │                          ├──────────────────────►│                    │
 │                          │                       │ 3. SELECT user     │
 │                          │                       ├───────────────────►│
 │                          │                       │ 4. user row        │
 │                          │                       │◄───────────────────┤
 │                          │                       │ 5. BCrypt.Verify   │
 │                          │                       │ 6. JwtHelper.Issue │
 │                          │                       │ 7. INSERT refresh_token
 │                          │                       ├───────────────────►│
 │                          │ 8. {accessToken, refreshToken, user}         │
 │                          │◄──────────────────────┤                    │
 │ 9. 存 localStorage       │                       │                    │
 │◄─────────────────────────┤                       │                    │
```

### 2.4 控制器骨架

```csharp
// HomeMind.Api/Controllers/AuthController.cs
[ApiController]
[Route("api/v1/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _auth;
    public AuthController(IAuthService auth) => _auth = auth;

    [HttpPost("register")]
    public async Task<ActionResult<ApiResponse<LoginResultDto>>> Register(RegisterRequest req)
    {
        var r = await _auth.RegisterAsync(req.Phone, req.Password, req.DisplayName);
        return Ok(ApiResponse.Ok(r));
    }

    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<LoginResultDto>>> Login(LoginRequest req)
    {
        var r = await _auth.LoginAsync(req.Phone, req.Password);
        return Ok(ApiResponse.Ok(r));
    }

    [HttpPost("refresh")]
    public async Task<ActionResult<ApiResponse<LoginResultDto>>> Refresh(RefreshRequest req)
    {
        var r = await _auth.RefreshAsync(req.RefreshToken);
        return Ok(ApiResponse.Ok(r));
    }

    [HttpGet("me")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<UserDto>>> Me()
    {
        var userId = long.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var me = await _auth.GetMeAsync(userId);
        return Ok(ApiResponse.Ok(me));
    }
}
```

---

## §3 数据库表结构（MySQL 8.0 DDL）

> 字符集：`utf8mb4` / 排序规则：`utf8mb4_unicode_ci`
> 命名约定：表名 `snake_case` 复数，字段 `snake_case`，时间字段 `xxx_at` / `xxx_at`（带时区存 `DATETIME`，应用层按 UTC 处理；MySQL 没有 `DATETIMEOFFSET`，统一用 `DATETIME(3)` 存 UTC，跨时区在 C# 用 `DateTimeOffset` 转换）。

### 3.1 统一响应

```sql
-- 无固定表，对应 C# 类：
-- public record ApiResponse<T>(int Code, string Msg, T? Data);
-- Code: 0=ok, 401=unauthorized, 403=forbidden, 404=not_found, 422=validation, 500=server_error
```

### 3.2 表清单

| 表 | 用途 | 关键字段 |
|---|---|---|
| `users` | 用户 | id, phone, email, password_hash, display_name, avatar |
| `todos` | 待办 | id, user_id, title, type, priority, status, due_date, repeat_rule, parent_id, pinned |
| `subtasks` | 子任务 | id, todo_id, text, done, seq |
| `attachments` | 附件元信息 | id, user_id, todo_id, name, mime, size_bytes, storage_path |
| `calendar_events` | 日历事件 | id, user_id, title, start_at, end_at, all_day, color, repeat_rule |
| `calendar_subscriptions` | iCal 订阅 | id, user_id, url, name, enabled, last_fetch_at |
| `ical_overrides` | iCal 事件重写 | id, user_id, source_event_uid, action(rename/hide/reschedule) |
| `ai_skills` | AI 技能 | id, user_id, name, prompt, scopes (JSON) |
| `user_settings` | 用户设置 (KV) | user_id, k, v |
| `ai_configs` | AI 配置（Key 加密） | user_id, endpoint, api_key_enc, model, temperature |
| `refresh_tokens` | Refresh Token | id, user_id, token_hash, expires_at, revoked_at, created_at |
| `ai_call_logs` | AI 调用审计 | id, user_id, scope, prompt_tokens, completion_tokens, latency_ms, status |
| `sync_records` | 同步元信息 | user_id, entity, last_pulled_at, last_pushed_at |

### 3.3 DDL

```sql
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ===== 用户 =====
CREATE TABLE IF NOT EXISTS `users` (
  `id`            BIGINT       NOT NULL AUTO_INCREMENT,
  `phone`         VARCHAR(20)  NULL COMMENT '手机号，国内唯一',
  `email`         VARCHAR(120) NULL,
  `password_hash` VARCHAR(255) NOT NULL COMMENT 'BCrypt hash，60 字节定长',
  `display_name`  VARCHAR(64)  NULL,
  `avatar`        VARCHAR(255) NULL,
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`    DATETIME(3)  NULL COMMENT '软删',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_phone` (`phone`),
  UNIQUE KEY `uk_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Refresh Token =====
CREATE TABLE IF NOT EXISTS `refresh_tokens` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT       NOT NULL,
  `token_hash` CHAR(64)     NOT NULL COMMENT 'refreshToken 原文 SHA-256 后的 hex',
  `expires_at` DATETIME(3)  NOT NULL,
  `revoked_at` DATETIME(3)  NULL,
  `created_at` DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `user_agent` VARCHAR(255) NULL,
  `ip`         VARCHAR(64)  NULL,
  PRIMARY KEY (`id`),
  KEY `idx_rt_user` (`user_id`, `revoked_at`),
  KEY `idx_rt_hash` (`token_hash`),
  CONSTRAINT `fk_rt_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Todo =====
CREATE TABLE IF NOT EXISTS `todos` (
  `id`           BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`      BIGINT       NOT NULL,
  `seq`          INT          NOT NULL DEFAULT 0,
  `title`        VARCHAR(255) NOT NULL,
  `description`  TEXT         NULL,
  `type`         VARCHAR(32)  NULL COMMENT 'work/life/study/other',
  `priority`     VARCHAR(8)   NULL COMMENT 'high/mid/low',
  `color`        VARCHAR(16)  NULL COMMENT '#rrggbb',
  `status`       VARCHAR(16)  NOT NULL DEFAULT 'pending' COMMENT 'pending/completed',
  `due_date`     DATETIME(3)  NULL,
  `remind_at`    DATETIME(3)  NULL,
  `repeat_rule`  VARCHAR(32)  NULL COMMENT 'none/daily/weekly/biweekly/monthly/yearly',
  `parent_id`    BIGINT       NULL COMMENT '未来支持 todo 树',
  `pinned`       TINYINT(1)   NOT NULL DEFAULT 0,
  `tags`         JSON         NULL COMMENT '["报告","紧急"]',
  `completed_at` DATETIME(3)  NULL,
  `created_at`   DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`   DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`   DATETIME(3)  NULL,
  PRIMARY KEY (`id`),
  KEY `idx_todos_user_due` (`user_id`, `due_date`),
  KEY `idx_todos_user_status` (`user_id`, `status`),
  KEY `idx_todos_user_updated` (`user_id`, `updated_at`),
  CONSTRAINT `fk_todos_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Subtask =====
CREATE TABLE IF NOT EXISTS `subtasks` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT,
  `todo_id`    BIGINT       NOT NULL,
  `text`       VARCHAR(255) NOT NULL,
  `done`       TINYINT(1)   NOT NULL DEFAULT 0,
  `seq`        INT          NOT NULL DEFAULT 0,
  `created_at` DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_subtasks_todo` (`todo_id`, `seq`),
  CONSTRAINT `fk_subtasks_todo` FOREIGN KEY (`todo_id`) REFERENCES `todos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Attachment =====
CREATE TABLE IF NOT EXISTS `attachments` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`     BIGINT       NOT NULL,
  `todo_id`     BIGINT       NULL,
  `name`        VARCHAR(255) NOT NULL,
  `mime`        VARCHAR(64)  NULL,
  `size_bytes`  BIGINT       NOT NULL DEFAULT 0,
  `storage_path` VARCHAR(512) NOT NULL COMMENT '相对路径 uploads/{userId}/{guid}.{ext}',
  `created_at`  DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_attach_user` (`user_id`, `created_at`),
  KEY `idx_attach_todo` (`todo_id`),
  CONSTRAINT `fk_attach_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_attach_todo` FOREIGN KEY (`todo_id`) REFERENCES `todos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Calendar Event =====
CREATE TABLE IF NOT EXISTS `calendar_events` (
  `id`          BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`     BIGINT       NOT NULL,
  `title`       VARCHAR(255) NOT NULL,
  `description` TEXT         NULL,
  `start_at`    DATETIME(3)  NOT NULL,
  `end_at`      DATETIME(3)  NULL,
  `all_day`     TINYINT(1)   NOT NULL DEFAULT 0,
  `color`       VARCHAR(16)  NULL,
  `opacity`     DECIMAL(3,2) NULL DEFAULT 1.00,
  `repeat_rule` VARCHAR(32)  NULL,
  `location`    VARCHAR(255) NULL,
  `created_at`  DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`  DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `deleted_at`  DATETIME(3)  NULL,
  PRIMARY KEY (`id`),
  KEY `idx_events_user_start` (`user_id`, `start_at`),
  KEY `idx_events_user_updated` (`user_id`, `updated_at`),
  CONSTRAINT `fk_events_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Calendar Subscription (iCal) =====
CREATE TABLE IF NOT EXISTS `calendar_subscriptions` (
  `id`            BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`       BIGINT       NOT NULL,
  `url`           VARCHAR(2048) NOT NULL,
  `name`          VARCHAR(128) NULL,
  `enabled`       TINYINT(1)   NOT NULL DEFAULT 1,
  `last_fetch_at` DATETIME(3)  NULL,
  `last_error`    VARCHAR(512) NULL,
  `created_at`    DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sub_user_url` (`user_id`, `url`(255)),
  CONSTRAINT `fk_sub_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== iCal Override =====
CREATE TABLE IF NOT EXISTS `ical_overrides` (
  `id`                BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`           BIGINT       NOT NULL,
  `subscription_id`   BIGINT       NOT NULL,
  `source_event_uid`  VARCHAR(255) NOT NULL COMMENT 'iCal UID',
  `action`            VARCHAR(16)  NOT NULL COMMENT 'rename/hide/reschedule',
  `patch`             JSON         NULL COMMENT '改后字段',
  `created_at`        DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ovr_event` (`user_id`, `source_event_uid`),
  CONSTRAINT `fk_ovr_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ovr_sub` FOREIGN KEY (`subscription_id`) REFERENCES `calendar_subscriptions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== AI Skill =====
CREATE TABLE IF NOT EXISTS `ai_skills` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT       NOT NULL,
  `name`       VARCHAR(128) NOT NULL,
  `prompt`     TEXT         NOT NULL,
  `scopes`     JSON         NOT NULL COMMENT '["week","day","import"]',
  `is_builtin` TINYINT(1)   NOT NULL DEFAULT 0,
  `created_at` DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_skills_user` (`user_id`),
  CONSTRAINT `fk_skills_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== User Settings (KV) =====
CREATE TABLE IF NOT EXISTS `user_settings` (
  `user_id`    BIGINT       NOT NULL,
  `k`          VARCHAR(64)  NOT NULL,
  `v`          TEXT         NULL,
  `updated_at` DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`user_id`, `k`),
  CONSTRAINT `fk_usrset_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== AI Config（Key 加密） =====
CREATE TABLE IF NOT EXISTS `ai_configs` (
  `user_id`     BIGINT       NOT NULL,
  `endpoint`    VARCHAR(255) NOT NULL DEFAULT 'https://api.openai.com/v1',
  `api_key_enc` TEXT         NOT NULL COMMENT 'DataProtection 加密后的 base64',
  `model`       VARCHAR(64)  NOT NULL DEFAULT 'gpt-4o-mini',
  `temperature` DECIMAL(3,2) NOT NULL DEFAULT 0.70,
  `updated_at`  DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_aicfg_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== AI Call Log =====
CREATE TABLE IF NOT EXISTS `ai_call_logs` (
  `id`              BIGINT       NOT NULL AUTO_INCREMENT,
  `user_id`         BIGINT       NOT NULL,
  `scope`           VARCHAR(32)  NOT NULL COMMENT 'week/day/import',
  `skill_id`        BIGINT       NULL,
  `prompt_tokens`   INT          NOT NULL DEFAULT 0,
  `completion_tokens` INT        NOT NULL DEFAULT 0,
  `latency_ms`      INT          NOT NULL DEFAULT 0,
  `status`          VARCHAR(16)  NOT NULL COMMENT 'ok/error/timeout',
  `error_msg`       VARCHAR(512) NULL,
  `created_at`      DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_ailog_user_time` (`user_id`, `created_at`),
  CONSTRAINT `fk_ailog_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== Sync Record =====
CREATE TABLE IF NOT EXISTS `sync_records` (
  `user_id`        BIGINT       NOT NULL,
  `entity`         VARCHAR(32)  NOT NULL COMMENT 'todos/calendar_events/skills/...',
  `last_pulled_at` DATETIME(3)  NULL,
  `last_pushed_at` DATETIME(3)  NULL,
  PRIMARY KEY (`user_id`, `entity`),
  CONSTRAINT `fk_sync_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
```

### 3.4 索引策略

- 所有业务表带 `idx_xxx_user_updated (user_id, updated_at)` 以支持 LWW 增量同步
- `todos` 还带 `idx_todos_user_due` 给日历格子用
- 所有外键 `ON DELETE CASCADE` —— 删用户即清数据
- 软删字段 `deleted_at`：默认不查（用 SqlSugar `IsDeleted = true` 全局过滤器）

---

## §4 实体类骨架（SqlSugar）

放置位置：`HomeMind.Common.Model/Entities/*.cs`

```csharp
// HomeMind.Common.Model/Entities/User.cs
using SqlSugar;

namespace HomeMind.Common.Model.Entities;

[SugarTable("users")]
public class User
{
    [SugarColumn(IsPrimaryKey = true, IsIdentity = true)]
    public long Id { get; set; }

    [SugarColumn(Length = 20, IsNullable = true)]
    public string? Phone { get; set; }

    [SugarColumn(Length = 120, IsNullable = true)]
    public string? Email { get; set; }

    [SugarColumn(Length = 255, IsNullable = false)]
    public string PasswordHash { get; set; } = default!;

    [SugarColumn(Length = 64, IsNullable = true)]
    public string? DisplayName { get; set; }

    [SugarColumn(Length = 255, IsNullable = true)]
    public string? Avatar { get; set; }

    [SugarColumn(IsNullable = false)]
    public DateTime CreatedAt { get; set; }

    [SugarColumn(IsNullable = false)]
    public DateTime UpdatedAt { get; set; }

    [SugarColumn(IsNullable = true, IsOnlyIgnoreUpdate = true)]
    public DateTime? DeletedAt { get; set; }
}
```

```csharp
// HomeMind.Common.Model/Entities/Todo.cs
using SqlSugar;

namespace HomeMind.Common.Model.Entities;

[SugarTable("todos")]
public class Todo
{
    [SugarColumn(IsPrimaryKey = true, IsIdentity = true)]
    public long Id { get; set; }

    [SugarColumn(IsNullable = false)]
    public long UserId { get; set; }

    public int Seq { get; set; }

    [SugarColumn(Length = 255, IsNullable = false)]
    public string Title { get; set; } = default!;

    [SugarColumn(ColumnDataType = "text", IsNullable = true)]
    public string? Description { get; set; }

    [SugarColumn(Length = 32, IsNullable = true)]
    public string? Type { get; set; }

    [SugarColumn(Length = 8, IsNullable = true)]
    public string? Priority { get; set; }

    [SugarColumn(Length = 16, IsNullable = true)]
    public string? Color { get; set; }

    [SugarColumn(Length = 16, IsNullable = false, DefaultValue = "pending")]
    public string Status { get; set; } = "pending";

    public DateTime? DueDate { get; set; }
    public DateTime? RemindAt { get; set; }

    [SugarColumn(Length = 32, IsNullable = true)]
    public string? RepeatRule { get; set; }

    public long? ParentId { get; set; }

    public bool Pinned { get; set; }

    [SugarColumn(ColumnDataType = "json", IsNullable = true)]
    public string? TagsJson { get; set; }   // 存 JSON 字符串，应用层用 System.Text.Json 解析

    public DateTime? CompletedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime? DeletedAt { get; set; }
}

[SugarTable("subtasks")]
public class Subtask
{
    [SugarColumn(IsPrimaryKey = true, IsIdentity = true)]
    public long Id { get; set; }
    public long TodoId { get; set; }
    [SugarColumn(Length = 255, IsNullable = false)]
    public string Text { get; set; } = default!;
    public bool Done { get; set; }
    public int Seq { get; set; }
    public DateTime CreatedAt { get; set; }
}
```

> 其余 11 个实体类按相同模式给出（`RefreshToken / Attachment / CalendarEvent / CalendarSubscription / ICalOverride / AiSkill / UserSetting / AiConfig / AiCallLog / SyncRecord`）。

---

## §5 仓储接口骨架

放置位置：`HomeMind.Common.IRepository/`

```csharp
// HomeMind.Common.IRepository/IBaseRepository.cs
using SqlSugar;
using System.Linq.Expressions;

namespace HomeMind.Common.IRepository;

public interface IBaseRepository<T> where T : class, new()
{
    ISqlSugarClient Db { get; }
    Task<T?> GetByIdAsync(long id);
    Task<List<T>> ListAsync(Expression<Func<T, bool>>? where = null);
    Task<List<T>> ListSinceAsync(DateTime since, Expression<Func<T, bool>>? where = null);
    Task<long> InsertAsync(T entity);
    Task<int> UpdateAsync(T entity);
    Task<int> DeleteAsync(long id);    // 软删
    Task<int> HardDeleteAsync(long id);
}
```

```csharp
// HomeMind.Common.IRepository/IUserRepository.cs
using HomeMind.Common.Model.Entities;

namespace HomeMind.Common.IRepository;

public interface IUserRepository : IBaseRepository<User>
{
    Task<User?> GetByPhoneAsync(string phone);
    Task<User?> GetByEmailAsync(string email);
}
```

```csharp
// HomeMind.Common.IRepository/ITodoRepository.cs
using HomeMind.Common.Model.Entities;

namespace HomeMind.Common.IRepository;

public interface ITodoRepository : IBaseRepository<Todo>
{
    Task<List<Todo>> ListByUserAsync(long userId, DateTime? since = null,
        string? status = null, string? type = null);
    Task<List<Todo>> ListDueBetweenAsync(long userId, DateTime from, DateTime to);
}
```

```csharp
// HomeMind.Common.IRepository/IRefreshTokenRepository.cs
using HomeMind.Common.Model.Entities;

namespace HomeMind.Common.IRepository;

public interface IRefreshTokenRepository : IBaseRepository<RefreshToken>
{
    Task<RefreshToken?> GetByHashAsync(string tokenHash);
    Task<int> RevokeAsync(long id);
    Task<int> RevokeAllForUserAsync(long userId);
}
```

实现位置：`HomeMind.Common.Repository/`

```csharp
// HomeMind.Common.Repository/BaseRepository.cs
using HomeMind.Common.IRepository;
using SqlSugar;

namespace HomeMind.Common.Repository;

public abstract class BaseRepository<T> : IBaseRepository<T> where T : class, new()
{
    protected readonly ISqlSugarClient _db;
    public ISqlSugarClient Db => _db;
    protected BaseRepository(ISqlSugarClient db) => _db = db;

    public virtual ISugarQueryable<T> Query => _db.Queryable<T>().Where("deleted_at IS NULL");

    public virtual async Task<T?> GetByIdAsync(long id) =>
        await _db.Queryable<T>().InSingleAsync(id);

    public virtual async Task<List<T>> ListAsync(System.Linq.Expressions.Expression<Func<T, bool>>? where = null)
    {
        var q = _db.Queryable<T>().Where("deleted_at IS NULL");
        if (where != null) q = q.Where(where);
        return await q.ToListAsync();
    }

    public virtual async Task<List<T>> ListSinceAsync(DateTime since,
        System.Linq.Expressions.Expression<Func<T, bool>>? where = null)
    {
        var q = _db.Queryable<T>().Where("updated_at > @since", new { since });
        if (where != null) q = q.Where(where);
        return await q.ToListAsync();
    }

    public virtual async Task<long> InsertAsync(T entity) =>
        await _db.Insertable(entity).ExecuteReturnIdentityAsync();

    public virtual async Task<int> UpdateAsync(T entity) =>
        await _db.Updateable(entity).IgnoreColumns("created_at").ExecuteCommandAsync();

    public virtual async Task<int> DeleteAsync(long id) =>
        await _db.Updateable<T>().SetColumns("deleted_at = NOW()").Where("id = @id", new { id }).ExecuteCommandAsync();

    public virtual async Task<int> HardDeleteAsync(long id) =>
        await _db.Deleteable<T>().Where("id = @id", new { id }).ExecuteCommandAsync();
}
```

---

## §6 服务接口骨架

放置位置：`HomeMind.Business.IServices/` 与 `HomeMind.Business.Services/`

```csharp
// HomeMind.Business.IServices/IAuthService.cs
using HomeMind.Common.Model.Dtos;

namespace HomeMind.Business.IServices;

public interface IAuthService
{
    Task<LoginResultDto> RegisterAsync(string phone, string password, string? displayName);
    Task<LoginResultDto> LoginAsync(string phone, string password);
    Task<LoginResultDto> RefreshAsync(string refreshToken);
    Task<UserDto> GetMeAsync(long userId);
    Task LogoutAsync(long userId, string refreshToken);
}
```

```csharp
// HomeMind.Business.IServices/ITodoService.cs
using HomeMind.Common.Model.Dtos;

namespace HomeMind.Business.IServices;

public interface ITodoService
{
    Task<List<TodoDto>> ListAsync(long userId, DateTime? since, string? status, string? type);
    Task<TodoDto> GetAsync(long userId, long id);
    Task<TodoDto> CreateAsync(long userId, TodoCreateDto dto);
    Task<TodoDto> UpdateAsync(long userId, long id, TodoUpdateDto dto);
    Task DeleteAsync(long userId, long id);
    Task<SubtaskDto> AddSubtaskAsync(long userId, long todoId, string text);
}
```

```csharp
// HomeMind.Business.Services/AuthService.cs（关键实现）
public class AuthService : IAuthService
{
    private readonly IUserRepository _users;
    private readonly IRefreshTokenRepository _refreshTokens;
    private readonly IJwtHelper _jwt;
    private readonly IEncryptionHelper _enc;

    public AuthService(IUserRepository users, IRefreshTokenRepository rt,
        IJwtHelper jwt, IEncryptionHelper enc)
    { _users = users; _refreshTokens = rt; _jwt = jwt; _enc = enc; }

    public async Task<LoginResultDto> LoginAsync(string phone, string password)
    {
        var user = await _users.GetByPhoneAsync(phone)
            ?? throw new ApiException(401, "用户不存在或密码错误");
        if (!BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
            throw new ApiException(401, "用户不存在或密码错误");

        return await IssueTokensAsync(user);
    }

    public async Task<LoginResultDto> RefreshAsync(string refreshToken)
    {
        var hash = Sha256(refreshToken);
        var rt = await _refreshTokens.GetByHashAsync(hash)
            ?? throw new ApiException(401, "无效 refresh token");
        if (rt.RevokedAt != null) throw new ApiException(401, "refresh token 已撤销");
        if (rt.ExpiresAt < DateTime.UtcNow) throw new ApiException(401, "refresh token 过期");

        var user = await _users.GetByIdAsync(rt.UserId)
            ?? throw new ApiException(401, "用户不存在");

        // 旋转：撤销旧 + 发新
        await _refreshTokens.RevokeAsync(rt.Id);
        return await IssueTokensAsync(user);
    }

    private async Task<LoginResultDto> IssueTokensAsync(User user)
    {
        var access = _jwt.IssueAccessToken(user.Id, user.Phone ?? "");
        var refresh = GenerateRefreshToken();
        await _refreshTokens.InsertAsync(new RefreshToken
        {
            UserId = user.Id,
            TokenHash = Sha256(refresh),
            ExpiresAt = DateTime.UtcNow.AddDays(7),
            CreatedAt = DateTime.UtcNow
        });
        return new LoginResultDto
        {
            AccessToken = access,
            RefreshToken = refresh,
            User = user.ToDto()
        };
    }

    private static string GenerateRefreshToken()
    {
        var bytes = new byte[32];
        System.Security.Cryptography.RandomNumberGenerator.Fill(bytes);
        return Microsoft.IdentityModel.Tokens.Base64UrlEncoder.Encode(bytes);
    }

    private static string Sha256(string s)
    {
        var bytes = System.Text.Encoding.UTF8.GetBytes(s);
        var hash = System.Security.Cryptography.SHA256.HashData(bytes);
        return Convert.ToHexString(hash).ToLowerInvariant();
    }
}
```

---

## §7 控制器路由表（与前端 §4.2 端点 1:1 对照）

> 前缀：`/api/v1`，所有响应统一包成 `ApiResponse<T> { code, msg, data }`
> 除明确标注 `[AllowAnonymous]` 外，默认都要 `[Authorize]`（JWT 鉴权）

| Method | Path | Auth | 控制器方法 | 请求 DTO | 响应 DTO |
|---|---|---|---|---|---|
| `POST` | `/auth/register` | Anonymous | `AuthController.Register` | `RegisterRequest` | `LoginResultDto` |
| `POST` | `/auth/login` | Anonymous | `AuthController.Login` | `LoginRequest` | `LoginResultDto` |
| `POST` | `/auth/refresh` | Anonymous | `AuthController.Refresh` | `RefreshRequest` | `LoginResultDto` |
| `GET`  | `/auth/me` | Required | `AuthController.Me` | — | `UserDto` |
| `GET`  | `/todos` | Required | `TodosController.List` | query: `since, status, type` | `List<TodoDto>` |
| `POST` | `/todos` | Required | `TodosController.Create` | `TodoCreateDto` | `TodoDto` |
| `PUT`  | `/todos/{id}` | Required | `TodosController.Update` | `TodoUpdateDto` | `TodoDto` |
| `DELETE` | `/todos/{id}` | Required | `TodosController.Delete` | — | `{ id }` |
| `POST` | `/todos/{id}/subtasks` | Required | `TodosController.AddSubtask` | `{ text }` | `SubtaskDto` |
| `PUT`  | `/todos/{id}/subtasks/{subId}` | Required | `TodosController.UpdateSubtask` | `{ text?, done? }` | `SubtaskDto` |
| `DELETE` | `/todos/{id}/subtasks/{subId}` | Required | `TodosController.DeleteSubtask` | — | `{ id }` |
| `GET`  | `/calendar/events` | Required | `CalendarController.ListEvents` | query: `from, to` | `List<CalendarEventDto>` |
| `POST` | `/calendar/events` | Required | `CalendarController.CreateEvent` | `CalendarEventCreateDto` | `CalendarEventDto` |
| `PUT`  | `/calendar/events/{id}` | Required | `CalendarController.UpdateEvent` | `CalendarEventUpdateDto` | `CalendarEventDto` |
| `DELETE` | `/calendar/events/{id}` | Required | `CalendarController.DeleteEvent` | — | `{ id }` |
| `GET`  | `/calendar/subscriptions` | Required | `CalendarController.ListSubscriptions` | — | `List<IcalSubscriptionDto>` |
| `POST` | `/calendar/subscriptions` | Required | `CalendarController.CreateSubscription` | `{ url, name? }` | `IcalSubscriptionDto` |
| `PUT`  | `/calendar/subscriptions/{id}` | Required | `CalendarController.UpdateSubscription` | `{ enabled?, name? }` | `IcalSubscriptionDto` |
| `DELETE` | `/calendar/subscriptions/{id}` | Required | `CalendarController.DeleteSubscription` | — | `{ id }` |
| `POST` | `/calendar/ical/fetch` | Required | `CalendarController.FetchIcal` | `{ url }` | `{ events: List<IcalEventDto> }` |
| `GET`  | `/skills` | Required | `SkillsController.List` | — | `List<AiSkillDto>` |
| `POST` | `/skills` | Required | `SkillsController.Create` | `AiSkillCreateDto` | `AiSkillDto` |
| `PUT`  | `/skills/{id}` | Required | `SkillsController.Update` | `AiSkillUpdateDto` | `AiSkillDto` |
| `DELETE` | `/skills/{id}` | Required | `SkillsController.Delete` | — | `{ id }` |
| `POST` | `/ai/generate` | Required | `AiController.Generate` | `{ scope, prompt, input, model?, temperature? }` | `{ content, usage }` |
| `GET`  | `/ai/config` | Required | `AiController.GetConfig` | — | `AiConfigDto` |
| `PUT`  | `/ai/config` | Required | `AiController.UpdateConfig` | `AiConfigUpdateDto` | `AiConfigDto` |
| `GET`  | `/weather` | Required | `WeatherController.Get` | query: `lat, lon` | `WeatherDto` |
| `GET`  | `/attachments/{id}` | Required | `AttachmentsController.Download` | — | binary stream |
| `POST` | `/attachments` | Required | `AttachmentsController.Upload` | `multipart/form-data` | `AttachmentDto` |
| `DELETE` | `/attachments/{id}` | Required | `AttachmentsController.Delete` | — | `{ id }` |
| `POST` | `/sync/pull` | Required | `SyncController.Pull` | `{ entity, since }` | `{ items, serverTime }` |
| `POST` | `/sync/push` | Required | `SyncController.Push` | `{ entity, items }` | `{ accepted, conflicts }` |
| `POST` | `/push/subscribe` | Required | `PushController.Subscribe` | `{ endpoint, p256dh, auth }` | `{ id }` |
| `DELETE` | `/push/subscribe/{id}` | Required | `PushController.Unsubscribe` | — | `{ id }` |

### 7.1 DTO 命名约定

- 请求：`XxxRequest` / `XxxCreateDto` / `XxxUpdateDto`（按 verb 区分）
- 响应：`XxxDto`（出参） / `LoginResultDto` / `ApiResponse<T>`
- 全部放 `HomeMind.Common.Model/Dtos/`

### 7.2 错误码映射

| code | 含义 | HTTP |
|---|---|---|
| 0 | 成功 | 200 |
| 400 | 参数错误 | 400 |
| 401 | 未鉴权 / Token 过期 | 401 |
| 403 | 无权访问 | 403 |
| 404 | 资源不存在 | 404 |
| 409 | 冲突（如已存在） | 409 |
| 422 | 业务校验失败 | 422 |
| 500 | 服务器异常 | 500 |

---

## §8 AI 网关与业务后端调用关系

> 本项目**只有一个 WebApi 进程**（`HomeMind.Api`），所以"网关 vs 业务"在同一进程内按 Controller 路由区分：
> - `/api/v1/ai/*` 走 `AiController`（用 `IHttpClientFactory` 调外部 OpenAI 兼容 endpoint）
> - `/api/v1/*` 其余走业务 Controller

### 8.1 AiController 骨架

```csharp
[ApiController]
[Route("api/v1/ai")]
[Authorize]
public class AiController : ControllerBase
{
    private readonly IAiConfigService _cfg;
    private readonly IHttpClientFactory _http;
    private readonly IAiCallLogService _log;
    public AiController(IAiConfigService cfg, IHttpClientFactory http, IAiCallLogService log)
    { _cfg = cfg; _http = http; _log = log; }

    [HttpPost("generate")]
    public async Task<ActionResult<ApiResponse<AiGenerateResultDto>>> Generate(AiGenerateRequest req)
    {
        var userId = long.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var cfg = await _cfg.GetAsync(userId);
        if (cfg == null) throw new ApiException(422, "未配置 AI，请先在设置中填入 API Key");

        var sw = System.Diagnostics.Stopwatch.StartNew();
        try
        {
            var client = _http.CreateClient("openai");
            client.Timeout = TimeSpan.FromSeconds(60);
            var body = new
            {
                model = string.IsNullOrEmpty(req.Model) ? cfg.Model : req.Model,
                temperature = req.Temperature ?? cfg.Temperature,
                messages = new[] {
                    new { role = "system", content = req.Prompt },
                    new { role = "user", content = req.Input }
                }
            };
            using var msg = new HttpRequestMessage(HttpMethod.Post, cfg.Endpoint.TrimEnd('/') + "/chat/completions");
            msg.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _enc.Unprotect(cfg.ApiKeyEnc));
            msg.Content = JsonContent.Create(body);
            using var resp = await client.SendAsync(msg);
            resp.EnsureSuccessStatusCode();
            var raw = await resp.Content.ReadFromJsonAsync<JsonElement>();
            var content = raw.GetProperty("choices")[0].GetProperty("message").GetProperty("content").GetString() ?? "";
            var usage = raw.GetProperty("usage");
            sw.Stop();
            await _log.LogAsync(userId, req.Scope, usage.GetProperty("prompt_tokens").GetInt32(),
                usage.GetProperty("completion_tokens").GetInt32(), (int)sw.ElapsedMilliseconds, "ok", null);
            return Ok(ApiResponse.Ok(new AiGenerateResultDto
            {
                Content = content,
                Usage = new AiUsageDto
                {
                    PromptTokens = usage.GetProperty("prompt_tokens").GetInt32(),
                    CompletionTokens = usage.GetProperty("completion_tokens").GetInt32()
                }
            }));
        }
        catch (Exception ex)
        {
            sw.Stop();
            await _log.LogAsync(userId, req.Scope, 0, 0, (int)sw.ElapsedMilliseconds, "error", ex.Message);
            throw;
        }
    }
}
```

### 8.2 Program.cs 注册 HttpClient

```csharp
builder.Services.AddHttpClient("openai", c =>
{
    c.Timeout = TimeSpan.FromSeconds(60);
    c.DefaultRequestHeaders.Add("User-Agent", "HomeMind/1.0");
});
```

---

## §9 安全 / 限流 / 审计

### 9.1 密码

- BCrypt cost = 11（首版默认值，硬件升级可改 12）
- 不存明文，不存可逆加密

### 9.2 JWT

- `Jwt:Key` 至少 32 字节，从环境变量 `HOMEMIND_JWT_KEY` 注入（不直接写 appsettings.json）
- Access Token 15 min，Refresh Token 7 d
- Refresh Token 旋转：旧 token 撤销后再发新；并发场景允许旧 token 在 24h 内一次性重试

### 9.3 CORS

```csharp
builder.Services.AddCors(opt => {
    opt.AddPolicy("Dev", p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
    opt.AddPolicy("Prod", p => p.WithOrigins(cfg.AllowedOrigins).AllowAnyHeader()
        .WithMethods("GET","POST","PUT","DELETE","PATCH"));
});
// app.UseCors(env.IsDevelopment() ? "Dev" : "Prod");
```

### 9.4 限流

- `AspNetCoreRateLimit` 包，按 userId 60 次/分钟（AI 端点独立 20 次/分钟）
- 全局默认 200 次/分钟（按 IP）

### 9.5 附件

- 单文件 ≤ 10MB；MIME 白名单 `image/*, application/pdf, text/*, application/zip`
- 存储：`wwwroot/uploads/{userId}/{guid}.{ext}`（首次访问时建目录）
- 读取：`GET /api/v1/attachments/{id}` → `PhysicalFile` 返回
- 清理：删 todo 时级联删附件文件（`IHostedService` 后台扫表）

### 9.6 审计

- AI 调用必写 `ai_call_logs`（已覆盖）
- 登录、注册、密码错误次数写 `auth_logs`（建议加，本计划不展开）

### 9.7 软删与级联

- 所有业务表 `deleted_at DATETIME(3) NULL`，SqlSugar 全局过滤器默认过滤
- 物理删除仅管理员后台用 `HardDeleteAsync`
- 删 `users` 触发 `ON DELETE CASCADE` 级联清掉 todos / events / tokens / configs

### 9.8 时区

- 数据库统一存 UTC（`DateTime` + 应用层 `DateTimeKind.Utc`）
- 出入参 DTO 用 `DateTimeOffset` 或带 `Z` 的 ISO 8601 字符串
- 前端 `new Date(s).toLocaleString()` 自动按用户时区渲染

---

## §10 实施顺序（给后续写后端的同事）

按下列顺序填充代码，每步可独立运行验证：

1. **基础设施**：`HomeMind.Common.Infrastructure` 加 `DbContext`（封装 SqlSugar）+ DI 扩展 `AddHomeMind()`；Program.cs 注册 Db、Swagger、JwtBearer、CORS
2. **Helpers**：`HomeMind.Common.Helpers` 写 `JwtHelper / BCryptHelper / EncryptionHelper / Sha256Helper`
3. **Model**：填充 12 个实体类（`User / Todo / Subtask / RefreshToken / Attachment / CalendarEvent / CalendarSubscription / ICalOverride / AiSkill / UserSetting / AiConfig / AiCallLog / SyncRecord`）
4. **IRepository + Repository**：写 `BaseRepository<T>` + 6 个具体仓储
5. **IServices + Services**：先做 `AuthService`（含注册/登录/刷新）+ `UserService`
6. **Controller**：先做 `AuthController`；Postman 跑通 `register / login / refresh / me`
7. **TodoService + TodosController**：跑通 `todos` CRUD
8. **CalendarService + CalendarController**：本地事件 CRUD + 订阅 + iCal 代理
9. **SkillsService + SkillsController**：CRUD
10. **AiConfigService + AiConfigController**：CRUD + DataProtection 加解密
11. **AiController** + **AiCallLogService** + `HttpClient` 注册：跑通一次真实 AI 调用
12. **WeatherController**：Open-Meteo 代理（`IMemoryCache` 缓存 1h）
13. **AttachmentsController**：上传 / 下载 / 删除
14. **SyncController**：增量 LWW 协议
15. **PushController**：Web Push 订阅
16. **Docker / 部署文档**

每完成一步，把对应的 §3 DDL 段执行一次，确保数据库与代码同步演进。

---

## §11 关联文档

- `PROJECT_PLAN.md §4` —— 端点定义来源
- `PROJECT_PLAN.md §5` —— 原 SQL Server DDL（已改写为 MySQL 适配版）
- `PROJECT_PLAN.md §3.5` (M3) / `§3.6` (M4) / `§3.7` (M5) —— 功能点与切片
