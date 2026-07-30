# 设计 Token

> 移动端 H5 视觉规范。精简自 TabFlow 22 套主题，首版只保留 3 套。

## 颜色

### 主题：violet（默认，暗）

| 变量 | 值 | 用途 |
|---|---|---|
| `--bg-primary` | `#0f172a` | 页面底色 |
| `--bg-secondary` | `#1e293b` | 次级容器 |
| `--bg-card` | `rgba(255,255,255,0.035)` | 卡片半透明 |
| `--accent` | `#6366f1` | 主色 |
| `--accent-light` | `#818cf8` | hover/active |
| `--accent-dark` | `#4f46e5` | 按下 |
| `--text-primary` | `#e0e7ff` | 主文字 |
| `--text-secondary` | `rgba(255,255,255,0.55)` | 次文字 |
| `--text-muted` | `rgba(255,255,255,0.3)` | 辅助 |
| `--priority-high` | `#ef4444` | 高优先级 |
| `--priority-mid` | `#f59e0b` | 中优先级 |
| `--priority-low` | `#10b981` | 低优先级 |

### 主题：ocean（暗蓝）

| 变量 | 值 |
|---|---|
| `--accent` | `#38bdf8` |
| `--accent-light` | `#7dd3fc` |
| `--accent-dark` | `#0ea5e9` |
| `--priority-high` | `#f87171` |
| `--priority-mid` | `#fbbf24` |
| `--priority-low` | `#34d399` |

### 主题：light（浅紫）

| 变量 | 值 |
|---|---|
| `--bg-primary` | `#f3e8ff` |
| `--bg-secondary` | `#fefefe` |
| `--text-primary` | `#2e1065` |
| `--accent` | `#a855f7` |

## 间距

首版使用 `vw` 单位（375 基准），`postcss-px-to-viewport-8-plugin` 自动转换。

| 场景 | px |
|---|---|
| 卡片内边距 | 16 |
| 卡片间距 | 12 |
| 圆角（卡片） | 16 |
| 圆角（按钮） | 8 |
| 圆角（小标签） | 4 |

## 字体

```
font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC',
             'Microsoft YaHei', 'Helvetica Neue', Arial, sans-serif;
```

| 用途 | px |
|---|---|
| 标题 | 22 / 18 / 16 |
| 正文 | 14 |
| 辅助 | 12 / 11 / 10 |

## 动画

- 页面切换：`opacity + translateY(8px)` 200ms
- 卡片入场：`fadeIn 0.3s`
- 按钮按下：`transform: scale(0.96)` 150ms

## 不变量

- 视图基准 375×812（iPhone X）
- 安全区：`env(safe-area-inset-top/bottom)`
- 移动端滚动隐藏 scrollbar
