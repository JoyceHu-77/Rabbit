# Rabbit_android

`Rabbit_android` 是爱兔会 Android 客户端首版迁移工程，与 `Rabbit_iOS` 同级。项目使用 Kotlin + Jetpack Compose，实现登录门控、五 Tab 主界面、主要业务流程，以及 API 优先、本地 DataStore/mock 回退的数据策略。

## 技术栈

- Kotlin
- Jetpack Compose + Material 3
- AndroidX Lifecycle ViewModel + StateFlow
- DataStore Preferences
- Retrofit + OkHttp + kotlinx.serialization
- Coil 图片加载

## 运行方式

1. 使用 Android Studio 打开 `Rabbit_android`。
2. 等待 Gradle 同步完成。
3. 运行 `app` 到 Android 8.0+ 设备或模拟器。

命令行环境具备 Android Gradle/SDK 时，也可以运行：

```bash
./gradlew :app:assembleDebug
```

## 演示账号

- `1`：管理员，具备救援审核、社区删帖、线下活动新增等能力。
- `2`：普通用户，具备浏览、发布、领养意向、社区互动、下单等能力。

## 已实现范围

- 登录门控与本地账号角色差异。
- 底部五 Tab：爱兔救援、爱兔领养、物资捐换、爱兔活动、个人页。
- 救援：搜索、状态筛选、我的发布、详情、发布待审、管理员审核/驳回/状态流转。
- 捐换：双列 Feed、详情弹窗、发布。
- 领养：流程说明、故事书、寄养/领养意向、社区发帖/点赞/管理员删除。
- 活动：打卡/云养、线下活动、管理员新增、爱心橱窗下单与云养币。
- 个人页：资料卡、消息、管理通知、订单、我的发布跨 Tab、地址、编辑资料、退出登录。
- 数据：Retrofit 尝试请求 iOS 同源后端，失败时使用本地 mock，并通过 DataStore 保存会话与业务缓存。

## 首版预留

- 地图选点、真实图片选择/上传、二维码展示、图片缩放等平台能力尚未做完整实现。
- 网络层首版按纯数组响应解析；若后端返回 envelope，可在 `base/RabbitApiService.kt` 增加对应 DTO。
