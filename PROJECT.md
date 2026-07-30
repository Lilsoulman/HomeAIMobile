# HomeAIMobile

> 移动端 H5 应用。设计思路复刻自 `D:\核心\插件\TabFlow`（Chrome 扩展），
> 去除浏览器特有能力（标签管理、代理、证书绕过等），保留并移植：
> 问候、Open-Meteo 天气、待办小组件、日历小组件、主题系统、中英文 i18n。

**首版仅完成首页 Dashboard。** 完整后续开发路线见 [PROJECT_PLAN.md](./PROJECT_PLAN.md)。

---

## 1. 技术栈

| 项 | 选型 |
|---|---|
| 框架 | Vue 2.7 + Vue Router 3 + Vuex 3 |
| UI 库 | Element UI 2.15（主） + Vant 2.13（移动端组件） |
| 构建 | Vue CLI 5 / Webpack 5 |
| 适配 | postcss-px-to-viewport-8-plugin（iPhone X 375 基准） |
| HTTP | axios（带 JWT 拦截器） |
| 持久化 | localStorage（vuex 订阅同步） |
| 主题 | CSS 变量 + `data-theme` 切换（精简 3 套） |

---

## 2. 目录结构

```
d:\核心\移动端\
├── package.json
├── vue.config.js                       # postcss-px-to-viewport + devServer
├── babel.config.js
├── public/index.html
├── src/
│   ├── main.js                         # Vue 初始化、注册 ElementUI/Vant
│   ├── App.vue                         # ThemeProvider + AppHeader + router-view + TabBar
│   ├── assets/styles/                  # index.css + themes.css + animations.css
│   ├── router/index.js                 # /  /todo  /calendar  /me
│   ├── store/
│   │   ├── index.js
│   │   ├── persistence.js              # vuex subscribe → localStorage
│   │   └── modules/
│   │       ├── settings.js             # 主题/语言/天气城市
│   │       ├── todos.js                # ⭐ 完整 store（含 homeList getter 复刻 TabFlow）
│   │       ├── calendar.js             # eventsForDate / upcoming
│   │       └── user.js                 # 预留 JWT
│   ├── services/
│   │   ├── http.js                     # axios 实例
│   │   ├── mock/                       # 假后端（首版用，路由式 mockAdapter）
│   │   └── api/index.js                # 统一 API 层
│   ├── utils/                          # date / weatherCodes / storage
│   └── components/
│       ├── common/                     # ThemeProvider / EmptyState
│       ├── layout/                     # AppHeader / TabBar
│       └── home/                       # Greeting / Weather / Stats / Todo / Calendar / QuickEntries
└── views/                              # Home / Todo / Calendar / Me / Placeholder
```

---

## 3. 启动

```powershell
cd d:\核心\移动端
npm install
npm run serve
# 浏览器打开 http://localhost:8080
# DevTools 切到 iPhone X 模拟（375×812）
```

---

## 4. 首版首页

| 模块 | 来源（TabFlow） | 移动端实现 |
|---|---|---|
| 问候 + 日期 | `js/newtab.js:1075` `getGreeting()` | `components/home/GreetingCard.vue` |
| 天气 | `js/newtab.js:727-759` `loadHomeWeather` | `components/home/WeatherCard.vue` + `services/api/weather.js` |
| 待办小组件 | `js/todo.js:2218-2365` `renderHomeWidget` | `components/home/TodoWidget.vue` + `store/getters.todos.homeList` |
| 日历小组件 | `js/calendar.js:1919-2028` `renderHomeWidget` | `components/home/CalendarWidget.vue` |
| 主题 | `css/newtab.css:5-127`（22 套 → 3 套精简） | `assets/styles/themes.css` |

**与 TabFlow 差异**：
- 单列纵向（移动端宽度限制，移除 3 列布局）
- 移除 `home-grid` 标签网格（标签页是浏览器概念）
- 移除音频面板、Top Domains（同上）
- 新增 **QuickEntries** 横滑快入口（占位指向后续模块）

---

## 5. 主题

3 套首版主题（在 Me 页切换）：

| key | 风格 |
|---|---|
| `violet` | 紫调暗色（默认） |
| `ocean` | 蓝调暗色 |
| `light` | 浅色 |

切换机制：`document.documentElement.setAttribute('data-theme', key)`，由 `ThemeProvider.vue` 监听 store 自动应用。

---

## 6. 数据层（首版）

```
component → vuex action → services/api → services/mock → 返回 mock
                                       ↘ 写入 localStorage
```

后续接入 C# 后端时，只需把 `src/services/api/index.js` 中 `mockAdapter` 调用改为真实 `http` 请求，store 与组件零改动。

---

## 7. 关键约定

- 视图基准：iPhone X 375×812，所有 px 通过 postcss 转 vw
- 字体：系统字体栈（`-apple-system, "PingFang SC", "Microsoft YaHei"…`），不内嵌 Maple Mono
- 跨页状态：所有 store state 通过 `store/persistence.js` 自动持久化到 localStorage
- 路由模式：`hash`（移动端 H5 + 静态部署友好）
- 占位页面：`/todo`、`/calendar`、`/me` 显示 Placeholder，指向 `PROJECT_PLAN.md §3`

---

## 8. 后续开发

见 [PROJECT_PLAN.md](./PROJECT_PLAN.md)，共 5 个里程碑（M1~M5）。
