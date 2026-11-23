# 设置页登录入口：DeepSeek 账号换 Xcodex 账号（Phase A）

日期：2026-11-20。分支：`feat/xcodex-managed-agents`。

## 背景与动机

App 转向远程引擎模式。原设置概览卡的「登录 DeepSeek 账号 / 或填写 API Key」用于配置手机本地运行的 DS key；改远程后，用户以 Xcodex 账号登录、配自己的 key、调用 xcodex.vip 的模型（接入文档：https://xcodex.vip/connect?editor=deepseek）。DS 账号体系最终要整体替换（Phase B），Phase A 先做最小替换。

## 目标

- 设置概览卡未登录态显示「登录 Xcodex 账号」，点击进入现有的 xcodex 设备登录 / 扫码配对流程（远程主机页里的 `_LoginCard`）。
- 中英文案同步，重新生成 l10n。

## 非目标（留给 Phase B）

- 不删 DS 账号体系：`account_state`、`AccountPage`、DS 余额 / 头像原样保留，只是不再从这张卡进入。
- 不动模型后端、余额来源。
- 不动 API Key 配置的其他入口（onboarding、engine 页等）。

## 方案（选定 A）

- **A（选定）**：只改概览卡未登录分支的文案与跳转（指向 `RemoteScreen`，其 `_RelaySection` / `_LoginCard` 已承载 xcodex 设备登录与扫码配对），DS 代码不动。改动面小、可交付，是通往 B 的垫脚石。
- **B（最终目的）**：移除 DS 账号体系，账号状态 / 余额 / 头像全走 xcodex。涉及账号层、余额、全 App 调用方，面大，现在不做。
- **C（放弃）**：新建独立 xcodex 登录页。远程页已有完整登录卡，另建是重复实现。

## 实现要点（A）

- `app/lib/ui/settings/settings_screen.dart` `_SettingsOverviewState`：`signedOut` / `unknown` 分支，标题 → 「登录 Xcodex 账号」，副标题 → xcodex 设备登录 / 扫码配对说明，`onTap` → `RemoteScreen`。已登录 DS 的分支、API Key 分支、remoteOnly 分支不动。
- l10n：`hub_zh.arb` / `hub_en.arb` 中 `hubSettingsSignInAccount` 文案改为 Xcodex 表述（该 key 仅此一处使用，直接改 key 文案）；`hubSettingsOrApiKey` 改为 xcodex 说明文案，可借用现有 `remoteXcodexSignInHelp` 的表述。改后跑 `python3 app/tool/l10n_merge.py`，再 `--check`。
- 验证：`(cd app && flutter pub get && flutter analyze && flutter test)`。

## 留给执行者的判断

- 副标题具体措辞（浏览器授权 / 扫码配对的描述）。
- xcodex 已登录后的卡片表现沿用现有 remoteOnly / 远程分支逻辑，不新增。
