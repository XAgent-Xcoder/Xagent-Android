# 设置概览卡 Phase B：xcodex 余额与头像预留口子（不实现）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在概览卡 xcodex 分支留好余额行与图片头像的钩子，服务端无数据时零行为变化；服务端就绪后只需后端实现接口、填字段，卡片自动长出。

**Architecture:** 照仓库既有「独立接口 + `backend is X`」惯用法（`RelayNetworkBackend` / `RelayPairingBackend`）新增可选接口 `RelayBalanceBackend`；`RelayUser` 加可选 `avatarUrl`；概览卡 xcodex 分支用 `is` 判断决定是否显示余额行与图片头像。不实现任何取数，无后端实现该接口，判断恒为 no-op。

**Tech Stack:** Flutter, Riverpod, l10n ARB。

**Spec:** `docs/superpowers/specs/2026-11-23-settings-xcodex-phase-b-hooks-design.md`

## Global Constraints

- 可选能力一律走「独立接口 + `backend is X` 判断」，不引入运行时开关或配置项。
- 不改 `RelayBackend` 主接口签名（消费方多）；新接口独立成类。
- 余额类型复用 `DeepSeekBalance`（`balance_state.dart:12`，含 `currency`/`total`/`available` + `symbol`），`formatMoney` 直接吃它，不新造类型。
- 头像渲染用 `CachedNetworkImage`（不扩 `AccountAvatar`，它吃 `AccountProfile`）。
- 中英 ARB 如新增文案须同步；本设计预期不新增文案（复用 `hubSettingsBalance`/`hubSettingsBalanceLow`）。
- 只暂存明确路径，不用 `git add .`；**本次不 commit**（用户本机测完再提交）。
- 验证命令：`(cd app && flutter pub get && flutter analyze && flutter test)`。

## Review Focus

- **接口无人实现时卡片不变**：没有后端 `implements RelayBalanceBackend`，xcodex 分支必须维持「图标 + 已登录」，现有 4 个测试全过。
- **余额行为 null 语义**：`balance()` 返回 null 时不显示余额行、不显示「余额不足」，不误判可用。
- **avatarUrl 为空不崩**：`avatarUrl` 为 null 时回退到图标占位，不画空 `Image`。
- **`is` 判断只改 xcodex 分支**：DS 的 `signedIn` 分支余额逻辑原样不动，避免回归。
- **透传不丢**：`RelayUser.avatarUrl` 从构造点透传，构造点仅 `dsh_remote_backend.dart:419` 一处。

---

### Task 1: 声明层 —— `RelayBalanceBackend` 接口与 `RelayUser.avatarUrl`

**Files:**
- Modify: `app/lib/remote/relay/relay_backend.dart`（加接口、加字段）
- Modify: `app/lib/remote/relay/dsh_remote_backend.dart:419`（构造点透传）
- Test: `app/test/remote/relay_balance_backend_test.dart`（新建）

**Interfaces:**
- Consumes: `DeepSeekBalance`（`balance_state.dart`）。
- Produces: `abstract interface class RelayBalanceBackend { Future<DeepSeekBalance?> balance(); }`；`RelayUser` 新增可选 `final String? avatarUrl`。Task 2 另需一个缓存异步结果的 `relayBalanceProvider`（`FutureProvider<DeepSeekBalance?>`，见下）。

- 新增 `relayBalanceProvider`（放 `hosts_state.dart`，紧跟 `relayAccountProvider`）：`FutureProvider<DeepSeekBalance?>`，读 `relayBackendProvider`，若 `is RelayBalanceBackend` 则 `await balance()`，否则返回 null；后端没实现该接口或取不到，值恒为 null。概览卡只 watch 这个 provider，不直接调异步方法。

- [ ] **Step 1: 写失败测试**

新建 `app/test/remote/relay_balance_backend_test.dart`，断言：
- 一个 `implements RelayBackend, RelayBalanceBackend` 的 fake，`backend is RelayBalanceBackend` 为 true；`UnavailableRelayBackend` 为 false。
- `RelayUser(id: 'x', displayName: 'd', avatarUrl: 'https://a/b.png')` 的 `.avatarUrl` 取回同值；不传时为 null。

- [ ] **Step 2: 运行确认失败**

Run: `cd app && flutter test test/remote/relay_balance_backend_test.dart -v`
Expected: FAIL —— `RelayBalanceBackend` 未定义、`avatarUrl` 无此参数。

- [ ] **Step 3: 加接口与字段**

`relay_backend.dart` 在 `RelayNetworkBackend` 之后加：
`abstract interface class RelayBalanceBackend { Future<DeepSeekBalance?> balance(); }`（doc 注释说明：服务端供余额时才实现，取不到返回 null）。`RelayUser` 构造加可选 `this.avatarUrl`，加 `final String? avatarUrl;`（doc：服务端供头像时才非空）。

- [ ] **Step 4: 构造点透传**

`dsh_remote_backend.dart:419` 的 `_user()` 暂不接 `RemoteUser`（该对象无 avatarUrl 字段），保持 `avatarUrl` 为默认 null；等 `RemoteUser` 补字段后再填。加一行注释说明。

- [ ] **Step 5: 运行确认通过**

Run: `cd app && flutter test test/remote/relay_balance_backend_test.dart -v`
Expected: PASS。

- [ ] **Step 6: 提交**

```bash
git add app/lib/remote/relay/relay_backend.dart app/lib/remote/relay/dsh_remote_backend.dart app/test/remote/relay_balance_backend_test.dart
git commit -m "feat(relay): 预留 xcodex 余额接口与头像字段

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 2: 消费层 —— 概览卡 xcodex 分支显示余额与图片头像

**Files:**
- Modify: `app/lib/ui/settings/settings_screen.dart`（xcodex 分支 `is` 判断）
- Test: `app/test/settings/settings_overview_xcodex_test.dart`（扩既有测试）

**Interfaces:**
- Consumes: `RelayBalanceBackend`、`RelayUser.avatarUrl`、`relayBalanceProvider`（Task 1）、`formatMoney`/`hubSettingsBalance`/`hubSettingsBalanceLow`。
- Produces: 概览卡 xcodex 分支在接口实现且返回非空时显示余额行；`avatarUrl` 非空时显示 `CachedNetworkImage`，否则图标占位。

- [ ] **Step 1: 扩失败测试**

在既有测试文件加一个 case：override `relayAccountProvider` 为一个 user 带 `avatarUrl` 的 `_FixedRelayAccount`，override `relayBackendProvider` 为一个 `implements RelayBackend, RelayBalanceBackend` 的 fake（加进 `_overrides()` 脚手架，新增一个可选参数），`balance()` 返回 `DeepSeekBalance(currency: 'CNY', total: 42.5)`。断言：出现 `hubSettingsBalance` 的「余额 ¥42.50」文案、出现 `CachedNetworkImage`。再补一个：`relayBackendProvider` 不实现 `RelayBalanceBackend` 时，维持「图标 + 已登录」、无余额文案、无 `Image`。

- [ ] **Step 2: 运行确认失败**

Run: `cd app && flutter test test/settings/settings_overview_xcodex_test.dart -v`
Expected: 新增的余额/头像断言 FAIL（卡片还不读接口）。

- [ ] **Step 3: 概览卡 xcodex 分支加判断**

`settings_screen.dart` xcodex 分支：读 `relayBackendProvider`，若 `is RelayBalanceBackend` 则 `await`-free 地取余额（用 `ref.watch` 一个派生 provider 或在该分支内读），非空时 `subtitle` 走 `balanceLine` 同款逻辑（低额用 `hubSettingsBalanceLow`），`leading` 有 `avatarUrl` 时用 `CachedNetworkImage` 包一层圆角、否则维持 `OverviewGlyph(AppIcons.account)`。DS `signedIn` 分支不动。

- [ ] **Step 4: 运行确认通过**

Run: `cd app && flutter test test/settings/settings_overview_xcodex_test.dart -v`
Expected: PASS（含原 4 个测试）。

- [ ] **Step 5: 全量验证**

Run: `cd app && flutter analyze && flutter test test/settings/ && flutter test test/remote/`
Expected: analyze 无新告警；settings 与 remote 全过。

- [ ] **Step 6: 提交**

```bash
git add app/lib/ui/settings/settings_screen.dart app/test/settings/settings_overview_xcodex_test.dart
git commit -m "feat(settings): 概览卡 xcodex 分支预留余额行与头像

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---
