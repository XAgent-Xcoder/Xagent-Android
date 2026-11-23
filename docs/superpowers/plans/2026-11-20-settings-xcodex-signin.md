# 设置概览卡登录入口 DeepSeek→Xcodex 实施计划（Phase A）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 设置页概览卡未登录态显示「登录 xcodex 账号」并指向 xcodex 设备登录/扫码配对流程，不再展示 DeepSeek 账号入口。

**Architecture:** 只改 `settings_screen.dart` 里 `_SettingsOverviewState` 的 `signedOut`/`unknown` 分支文案与 `onTap` 目标（`AccountPage` → `RemoteScreen`），复用远程页已存在的 xcodex 登录卡（`_RelaySection`/`_LoginCard`）。l10n 键 `hubSettingsSignInAccount`/`hubSettingsOrApiKey` 中英同步改文案并重新生成。DS 账号体系（`account_state`、`AccountPage`、DS 余额/头像）保留不删，留给 Phase B。

**Tech Stack:** Flutter, Riverpod, l10n ARB（`app/lib/l10n/parts/*.arb` + 生成器 `python3 app/tool/l10n_merge.py`）。

**Spec:** `docs/superpowers/specs/2026-11-20-settings-xcodex-signin-design.md`

## Global Constraints

- 界面文案中英两版同步：改 `app/lib/l10n/parts/*.arb` 与对应 `.en.arb`，再跑生成器；不手改 `l10n/gen/` 产物。
- 改 l10n 输入后必须运行 `python3 app/tool/l10n_merge.py`，并用 `--check` 确认生成结果一致。
- 只改概览卡的未登录分支；已登录 DS、API Key、remoteOnly 分支一律不动。
- 验证命令：`(cd app && flutter pub get && flutter analyze && flutter test)`。
- 不删 `account_state`、`AccountPage`、DS 余额/头像相关代码（Phase B 才清）。
- 只暂存明确路径，不用 `git add .` / `git add -A`；未经要求不 commit。

## Review Focus

- **签名态概览卡**：`signedOut`/`unknown` 时标题必须是 xcodex 文案，不能再出现 "DeepSeek"；测试应断言 `hubSettingsSignInAccount` 的新文案出现在卡上，且不再渲染 `hubSettingsOrApiKey` 的旧 "API Key" 措辞。
- **点击跳转**：该分支 `onTap` 必须导航到 `RemoteScreen`（其 `_RelaySection`/`_LoginCard` 承载 xcodex 登录），而非 `AccountPage`。
- **已登录分支不受影响**：`signedIn`/API Key/remoteOnly 的展示与跳转必须原样保留，避免回归。
- **l10n 生成一致**：`l10n_merge.py --check` 必须通过，说明 `parts/` 输入与 `gen/` 产物同步。
- **无孤立文案**：改后 `hubSettingsSignInAccount`/`hubSettingsOrApiKey` 只在概览卡使用，不应出现残留的 DeepSeek 账号入口。

---

### Task 1: 概览卡未登录分支换 xcodex 文案并指向 RemoteScreen

**Files:**
- Modify: `app/lib/ui/settings/settings_screen.dart:455-459`（`signedOut`/`unknown` 分支）
- Modify: `app/lib/l10n/parts/hub_zh.arb:72-73`、`app/lib/l10n/parts/hub_en.arb:72-73`（两个键的文案）
- Test: `app/test/settings/settings_overview_xcodex_test.dart`（新建）

**Interfaces:**
- Consumes: `AccountState`（`app/lib/state/account_state.dart`）、`AccountPhase.signedOut`/`.unknown`、`RemoteScreen`（`app/lib/ui/remote/remote_screen.dart`）、l10n 生成器。
- Produces: 概览卡未登录态显示新 xcodex 文案；`onTap` → `RemoteScreen`。后续任务无依赖。

- [ ] **Step 1: 写失败测试**

新建 `app/test/settings/settings_overview_xcodex_test.dart`，复用现有 `settings_overview_remote_test.dart` 的脚手架（`FixedAccount`、`FixedHosts`、`golden_harness.dart`），但把 runtime 设为已安装（`RuntimePhase.installed`）以落在**本地** `signedOut` 分支而非 `remoteOnly` 分支。断言：
- 概览卡标题文本等于 `appL10n.hubSettingsSignInAccount`（新 xcodex 文案），且不含 "DeepSeek"。
- 不再出现 `hubSettingsOrApiKey` 的 "API Key" 文案。
- 卡片 `onTap` 触发后 `find.byType(RemoteScreen)` 找到 `RemoteScreen`（导航目标），而不是 `AccountPage`。

（脚手架的 provider 覆盖、`flutter_test_config` 等完全照搬 `settings_overview_remote_test.dart`，仅改 runtime 为 installed、断言目标为上述三点。）

- [ ] **Step 2: 运行测试确认失败**

Run: `cd app && flutter test test/settings/settings_overview_xcodex_test.dart -v`
Expected: FAIL——标题仍是 "登录 DeepSeek 账号"，`onTap` 仍是 `AccountPage`。

- [ ] **Step 3: 改 l10n 输入**

`app/lib/l10n/parts/hub_zh.arb`：
- `"hubSettingsSignInAccount": "登录 xcodex 账号"`
- `"hubSettingsOrApiKey": "扫码配对或浏览器授权登录"`（该键仍被引用，但措辞换成 xcodex 说明；Phase B 删除此键）

`app/lib/l10n/parts/hub_en.arb`：
- `"hubSettingsSignInAccount": "Sign in to xcodex"`
- `"hubSettingsOrApiKey": "Pair by QR or sign in in a browser"`

- [ ] **Step 4: 改概览卡分支与跳转**

`settings_screen.dart` 第 455-459 行的 `signedOut`/`unknown` 分支保留 `hubSettingsSignInAccount` 作为标题；把第 478 行的
`onTap: () => _push(hostLink != null ? const RemoteScreen() : const AccountPage())`
改为：仅当 `hostLink != null` 走 `RemoteScreen`，否则（本地未登录）走 `RemoteScreen`。即本地未登录态直接 `_push(const RemoteScreen())`（xcodex 登录卡在其 `_RelaySection` 中）；remoteOnly 态仍用 `RemoteScreen`。两分支都指向 `RemoteScreen`，`AccountPage` 不再被该卡引用。

- [ ] **Step 5: 重新生成 l10n 产物**

Run: `cd app && python3 tool/l10n_merge.py && python3 tool/l10n_merge.py --check`
Expected: `--check` 通过，`gen/` 中 `hubSettingsSignInAccount`/`hubSettingsOrApiKey` 为新文案。

- [ ] **Step 6: 运行测试确认通过**

Run: `cd app && flutter test test/settings/settings_overview_xcodex_test.dart -v`
Expected: PASS。

- [ ] **Step 7: 全量验证**

Run: `cd app && flutter analyze && flutter test test/settings/`
Expected: analyze 无新告警；settings 全部测试通过（含原 `settings_overview_remote_test.dart`）。

- [ ] **Step 8: 提交**

```bash
git add app/lib/ui/settings/settings_screen.dart app/lib/l10n/parts/hub_zh.arb app/lib/l10n/parts/hub_en.arb app/lib/l10n/gen/ app/test/settings/settings_overview_xcodex_test.dart
git commit -m "feat(settings): 概览卡未登录入口改指向 xcodex 登录

Signed-off-by: Joseph <joseph@users.noreply.github.com>
Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

## 后续两轮改动（已实现，晚于本文定稿）

Phase A 交付后又做了两轮，未随计划回写，这里补齐：

- **副标题去掉「扫码配对」**：`hubSettingsOrApiKey` 定稿为「使用浏览器授权登录」/ `Sign in in a browser`，不再提扫码配对——推翻 Step 3 的文案。
- **xcodex 已登录显示账号身份**：概览卡新增 `case _ when xcodex != null:` 分支（`settings_screen.dart`），xcodex 账号优先于 DeepSeek 账号展示 `displayName` 与「已登录」。验收测试 `settings_overview_xcodex_test.dart` 已按此新行为断言。

---
