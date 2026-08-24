# HomeMind 移动端文档

本目录描述 `mobile`（Flutter Material 3）客户端的产品边界、开发计划、接口接入和工程规范。移动端是 HomeMind 的日常控制端：固定“首页、场景、设备、我的”四个 Tab 与全局语音入口；字段与状态码以 Core Swagger 为准。

| 文档 | 作用 | 何时阅读 |
| --- | --- | --- |
| [移动端产品体验](mobile-product.md) | 四 Tab 职责、App/Web 分工和安全边界 | 新页面、路由或功能取舍前 |
| [移动端开发计划](development-plan.md) | 下线清理、交付顺序、验收与下一步任务 | 排期、拆分或完成功能时 |
| [移动端 API 接入](api-integration.md) | `ApiClient`、Repository、认证刷新、场景与确认边界 | 新增或修改 API 调用时 |
| [开发规范](DEVELOPMENT_GUIDELINES.md) | Dart、状态、路由、数据和质量规则 | 编码与评审时 |
| [UI 风格指南](UI_STYLE_GUIDE.md) | 设计令牌、排版、布局和状态组件 | 调整视觉或组件时 |

共享事实来源：`../../core/docs/product.md` 是全产品入口，`../../core/docs/api-integration.md` 是跨端 API 契约，运行中的 Swagger 是字段、参数、权限和样例的唯一事实来源。改动移动端功能前，按需求阅读本目录对应文档及 `AGENTS.md`；不得为已下线领域新增入口、接口副本或过程日志。
