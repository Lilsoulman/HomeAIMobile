# HomeMind 移动端文档

本目录描述 `mobile`（Flutter Material 3）客户端的产品边界、开发计划、接口接入和工程规范。接口字段与状态码以 Core 服务 Swagger 为准，移动端只维护 DTO 映射与用户体验规则。

| 文档 | 作用 | 何时阅读 |
| --- | --- | --- |
| [移动端产品体验](mobile-product.md) | 五个主入口、移动端/ Web 分工与安全边界 | 新页面、路由或功能取舍前 |
| [移动端开发计划](development-plan.md) | 交付顺序、实现约束和验收 | 排期、拆分或完成功能时 |
| [移动端 API 接入](api-integration.md) | `ApiClient`、Repository、认证刷新和异步运行流 | 新增或修改 API 调用时 |
| [开发规范](DEVELOPMENT_GUIDELINES.md) | Dart、状态、路由、数据和质量规则 | 编码与评审时 |
| [UI 风格指南](UI_STYLE_GUIDE.md) | 设计令牌、排版、布局和组件状态 | 调整视觉或组件时 |

共享事实来源：`D:\HomeMind\core\docs\README.md` 为全产品入口，`D:\HomeMind\core\docs\api-integration.md` 为跨端 API 契约，运行中的 `/swagger` 为字段、参数和样例的唯一事实来源。

改动移动端功能前，按需求阅读本目录对应文档及 `AGENTS.md`；不要创建按版本堆叠的设计稿、接口副本或过程日志。
