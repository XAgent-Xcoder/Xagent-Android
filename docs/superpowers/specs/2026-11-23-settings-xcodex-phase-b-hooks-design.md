# 设置概览卡 Phase B：xcodex 余额与头像的预留口子（不实现）

日期：2026-11-23。

## 背景

Phase A（登录入口换 xcodex）已完成。Phase B 的四项里，账号身份显示已在跑，模型后端与 API Key 不涉及 App 侧数据源，**余额与头像卡在 `agent.xcodex.vip` 服务端没有数据**：

- 余额：中继协议（`RelayBackend`）无余额方法，`RelayUser` 无金额/币种/可用性字段。
- 头像：xcodex 账号信息无头像地址，已登录卡片只能画图标占位。

## 目标

只留口子，不实现取数：

1. 新增可选接口 `RelayBalanceBackend`（照 `RelayNetworkBackend` / `RelayPairingBackend` 的既有惯用法），带一个返回余额数据（金额、币种、是否可用）的方法；取不到返回 null。
2. `RelayUser` 增加可选 `avatarUrl` 字段（构造点仅 `dsh_remote_backend.dart` 一处）。
3. 概览卡 xcodex 分支加一处 `is` 判断：后端实现 `RelayBalanceBackend` 且返回非空时显示余额行（复用 `hubSettingsBalance` / `hubSettingsBalanceLow`），有 `avatarUrl` 时用 `AccountAvatar` 之外的普通图片头像；否则维持现状（图标 + 「已登录」）。

现在这段判断恒为 no-op，零行为变化。服务端就绪后只需后端 implement 接口、填字段，卡片自动长出，不动卡片逻辑。

## 非目标

- 不实现余额/头像的实际取数（服务端没有接口）。
- 不动 DS 账号体系（`account_state`、`AccountPage`、DS 余额/头像仍原样保留，Phase B 全量移除是另一个更大的活）。
- 不改模型后端与 API Key 入口。

## 约束

- 可选能力一律走「独立接口 + `backend is X` 判断」的既有写法，不引入运行时开关或配置项。
- 不改 `RelayBackend` 主接口签名（消费方多，加可选方法会逼所有 fake 改动）；新接口独立成类。
- 中英 ARB 如新增文案须同步；本设计预期不新增文案（复用既有余额 key）。

## 留给执行者的判断

- 余额数据结构字段名（`amount` / `currency` / `isAvailable` 的取舍）。
- 头像渲染组件：直接 `CachedNetworkImage` 还是扩 `AccountAvatar` 支持 URL 入参。

## 验收

`(cd app && flutter pub get && flutter analyze && flutter test)`；概览卡现有 golden 不变化（no-op 路径）。
