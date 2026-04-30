# Rabbit_iOS 架构说明（MVVM + Coordinator 薄层）

本文档对应 Cursor Skill **ios-swift-architecture-build** 的 Phase A 契约摘要。

## 分层目录

| 目录 | 职责 |
|------|------|
| `App/` | （预留）应用入口、全局 Coordinator 装配 |
| `Core/MainTab.swift` | 根级 `MainTab` 枚举（单一数据源） |
| `Core/Coordinator/` | `MainTabCoordinator`：根 Tab 选中状态，可扩展为深链接/外部跳转 |
| `Core/Storage/` | `RabbitCommunityStore`、`AdminNotificationsStore`（UserDefaults） |
| `Core/Networking/` | `RabbitAPIService`（Alamofire，与后端约定路径） |
| `Shared/DesignSystem/` | `Theme`、`LayoutMetrics` |
| `Shared/Components/` | 可复用 UI，如 `PostImageView` |
| `Shared/Utils/` | `L10n` 等横切能力 |
| `Features/Rescue/` | 救援：列表 View + `ViewModels/RescueListViewModel` |
| `Features/Adoption/` | 领养多段内容 |
| `Features/Donation/` | 物资捐换 |
| `Features/Activity/` | 活动主 Tab + `ActivitySupplementViews`（打卡/云养/线下/橱窗） |
| `Features/Profile/` | 个人页 + 消息/订单/意向等 Sheet |
| 仓库根下遗留 | `RootTabView`、`SceneDelegate`、`WelcomeGuideView`、救援详情/筛选等可按后续迭代迁入 Features |

## 状态与依赖

- **全局应用设置**：`AppDataStore`（`@Observable` + Core Data），经 `.environment(appData)` 注入。
- **救援列表**：`RescueListViewModel`（`@Observable`）承载列表、筛选、排序与加载状态，视图仅绑定与触发。
- **Coordinator**：`MainTabCoordinator` 持有 `selectedTab`；后续可将编程切换 Tab（如通知 deep link）收敛到 `select(_:)`。

## 后续演进（未在本次全部落地）

- 为 `RabbitAPIService` 增加协议抽象与注入，便于 Mock / 单测。
- 将 `WelcomeGuideView`、`RescueDetailView` 等迁入对应 Feature 目录。
- 使用 `Localizable.xcstrings` 替换 `L10n` 中的占位键。
