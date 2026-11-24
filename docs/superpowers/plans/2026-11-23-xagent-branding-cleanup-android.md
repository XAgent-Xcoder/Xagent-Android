# Xagent 品牌清理与素材摘除（Android 版）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按 dsh-Go ASSETS.md 的 fork 条款摘除全部受保护素材文件、保留功能框架，换入 Xagent 品牌与 X 形矢量图形，把包名和显示名统一为 Xagent。

**Architecture:** 参照 xagent-ios 的 `2026-11-23-xagent-branding-cleanup-design.md`：删素材目录 + 同步删 pubspec 声明 + 把运行时加载这些文件的代码改成不读文件（矢量绘制 / 空列表 / 占位）。品牌矢量用 Xagent-Logo-Developer-Kit 的 `09_Flutter/xagent_logo.dart`，启动图标用 `04_Android/res/`。伙伴小屋摘掉 Live2D 形象（删 `assets/companion/`），语音通话保留。

**Tech Stack:** Flutter, Riverpod, l10n ARB, Android Gradle (KTS)。

**Spec:** `/Users/joseph/projects/xagent-ios/docs/superpowers/specs/2026-11-23-xagent-branding-cleanup-design.md`（iOS 蓝本）+ 上游 `ASSETS.md`（素材限制）。

## Global Constraints

- 只删文件与对应声明，不改功能框架：`lib/pets/`、`lib/ui/pets/`、`lib/ui/star/`、`lib/ui/companion/` 的代码保留。
- 删素材后运行时不能崩：`WhaleSprites.load()` 改矢量；`StarPromptHost._maybeShow` 的 `precacheImage` 处理文件缺失；`PetPack.load()` 不再被内置 id 调用。
- 生成代码 `brand_glyph.g.dart` 是编译期常量、不读 `assets/brand/`，但路径是鱼尾形状，必须换成 X 形。
- 包名 `com.xcoder.agentport` → `com.xcoder.xagent`（用户已拍板换包名）。
- 界面文案中英 ARB 同步，跑 `python3 app/tool/l10n_merge.py` 后 `--check`。
- 只暂存明确路径，不用 `git add .`。commit 直接做，不推远端。
- 测试资源预算：空闲资源的一半以内（`--concurrency` 按此设）。
- 验证命令：`(cd app && flutter pub get && flutter analyze && flutter test)`。

## Review Focus

- **删素材后启动不崩**：`assets/whale/whale.json`、`assets/star/star_whale.webp`、`assets/companion/index.html` 不存在时，聊天流活动指示器、求 Star 弹窗、伙伴小屋 WebView 都不能抛未处理异常。
- **内置宠物清空后默认行为**：`builtInPets` 为空时 `adoptDefault()` 不能把"未选择"写成 `packExplicit=true`，否则宠物开关的回落路径失效。
- **品牌标换 X 后所有调用点**：`BrandMark` 在设置页脚、关于页、启动页、侧栏、分享卡、二维码、欢迎页的位置都要画出 X。
- **包名变更的连锁影响**：`AndroidManifest.xml` 里 `${applicationId}.phone.selfcheck`、`${applicationId}.shizuku` 等派生值跟着变，不能有硬编码的旧包名残留。
- **测试面**：删素材后 `test/shell/brand_mark_test.dart`、`test/chat/activity_strip_golden_test.dart`、`test/pets/*`、`test/star/*`、`test/companion/*` 会挂，逐个修。

---

### Task 1: 品牌图形换 X（brand 素材 + 生成代码 + 启动图标）

**Files:**
- Delete: `app/assets/brand/`（4 个 svg）、`app/lib/ui/shell/brand_glyph.g.dart`（旧鱼尾）
- Create: `app/lib/ui/shell/xagent_logo.dart`（从 logo 套件 `09_Flutter/` 拷入）
- Modify: `app/lib/ui/shell/brand_mark.dart`、`app/lib/ui/settings/appearance/app_icon_picker.dart`（改 import 与调用）
- Replace: `app/android/app/src/main/res/mipmap-*/ic_launcher*`（用套件 `04_Android/res/` 的）
- Test: `app/test/shell/brand_mark_test.dart`（改为验证 X 形）

**Interfaces:**
- Consumes: logo 套件 `09_Flutter/xagent_logo.dart` 的 `BrandMark`/`BrandWordmark`/`BrandSignature`。
- Produces: 品牌标在所有位置画 X；`brand_mark.dart` 的公开 API（`size`/`color`/`tile`/`aspect`/`visualCentre`）不变，调用方不动。

- [ ] **Step 1: 写失败测试**

`brand_mark_test.dart`：断言 `BrandMark` 画出的是 X 形（不再是鱼尾的路径特征）。旧测试若直接对比鱼尾的包围盒/像素则改为 X 的几何特征。

- [ ] **Step 2: 运行确认失败**（旧品牌标还是鱼尾）

- [ ] **Step 3: 换品牌矢量与启动图标**

从 logo 套件拷 `xagent_logo.dart`，删旧 `brand_glyph.g.dart` 和 `assets/brand/`。`brand_mark.dart` 改为包装新的 X 形绘制。Android mipmap 全套替换（保留 frost/ink/night 变体命名，前景换成 X）。鸿蒙 `make-launcher-icons.py` 的输入路径同步改。

- [ ] **Step 4: 运行确认通过**

- [ ] **Step 5: 提交**

```bash
git add app/lib/ui/shell/ app/lib/ui/settings/appearance/app_icon_picker.dart app/assets/brand/ app/android/app/src/main/res/mipmap-*/ app/test/shell/brand_mark_test.dart
git commit -m "品牌图形换 Xagent 的 X 标，启动图标换套件资源

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 2: 鲸尾指示器改矢量

**Files:**
- Delete: `app/assets/whale/`（whale.json + 4 张精灵图）
- Modify: `app/lib/ui/chat/widgets/whale_tail.dart`、`app/pubspec.yaml`（删 `- assets/whale/`）
- Test: `app/test/chat/activity_strip_golden_test.dart`

**Interfaces:**
- Consumes: 无外部输入。
- Produces: `WhaleTail` 公开 API（`level`/`color`/`height`/`still`/`aspect`）不变，`empty_state.dart` 和 `activity_strip.dart` 的调用点不动。

- [ ] **Step 1: 写失败测试**：`WhaleTail` 在没有 `assets/whale/` 时仍能渲染（不抛异常、不白屏），4 档 level 各有不同的呈现。

- [ ] **Step 2: 运行确认失败**（现在读 whale.json 会抛）

- [ ] **Step 3: 改矢量绘制**：`WhaleSprites.load()` 不再读文件，改为矢量绘制活动指示器（保留 4 档速度和交叉淡变）。`make_whale_sprites.py` 标注废弃。

- [ ] **Step 4: 运行确认通过**

- [ ] **Step 5: 提交**

```bash
git add app/lib/ui/chat/widgets/whale_tail.dart app/pubspec.yaml app/assets/whale/ app/test/chat/activity_strip_golden_test.dart
git commit -m "鲸尾活动指示器改矢量绘制，不再读精灵图

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 3: 内置宠物删，框架保留

**Files:**
- Delete: `app/assets/pets/deepy-whale/`、`app/assets/pets/whale-girl/`
- Modify: `app/lib/pets/pet_prefs.dart`、`app/lib/ui/pets/pet_picker.dart`、`app/lib/ui/companion/companion_chrome.dart:792`、`app/pubspec.yaml`（删两行 pet 声明）
- Test: `app/test/pets/pet_pack_test.dart`、`app/test/access/access_pet_default_test.dart` 等

**Interfaces:**
- Consumes: `noPetId` 常量（`pet_prefs.dart`）。
- Produces: `builtInPets` 为空列表，`defaultPetId` 走 `noPetId` 且不置 `packExplicit`。桌宠导入框架 `lib/pets/`、`lib/ui/pets/` 保留。

- [ ] **Step 1: 写失败测试**：`builtInPets` 为空时 `adoptDefault()` 不写 `packExplicit=true`，宠物开关切换仍能回落。

- [ ] **Step 2: 运行确认失败**

- [ ] **Step 3: 改**：`builtInPets = []`，`defaultPetId` 处理，`companion_chrome.dart:792` 的 `petPackProvider('whale-girl')` 清掉，pubspec 删两行。

- [ ] **Step 4: 运行确认通过**

- [ ] **Step 5: 提交**

```bash
git add app/lib/pets/pet_prefs.dart app/lib/ui/pets/pet_picker.dart app/lib/ui/companion/companion_chrome.dart app/pubspec.yaml app/assets/pets/deepy-whale/ app/assets/pets/whale-girl/ app/test/pets/ app/test/access/access_pet_default_test.dart
git commit -m "内置宠物摘除，桌宠导入框架保留

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 4: 求 Star 弹窗的鲸鱼贴纸删

**Files:**
- Delete: `app/assets/star/star_whale.webp`
- Modify: `app/lib/ui/star/star_prompt_dialog.dart`（移除 `StarPicture`）、`app/lib/ui/star/star_prompt_host.dart`（删 `precacheImage`）、`app/pubspec.yaml`（删 `- assets/star/`）
- Test: `app/test/star/*`

**Interfaces:**
- Consumes: 无。
- Produces: 求 Star 弹窗框架保留，只是没有鲸鱼贴纸了。

- [ ] **Step 1: 写失败测试**：`StarPromptHost._maybeShow` 在 `star_whale.webp` 不存在时不抛未处理异常，弹窗其余内容照常显示。

- [ ] **Step 2: 运行确认失败**（precacheImage 无 catch）

- [ ] **Step 3: 改**：删贴纸，`StarPicture` 从 Column 移除，`precacheImage` 删掉。

- [ ] **Step 4: 运行确认通过**

- [ ] **Step 5: 提交**

```bash
git add app/lib/ui/star/star_prompt_dialog.dart app/lib/ui/star/star_prompt_host.dart app/pubspec.yaml app/assets/star/ app/test/star/
git commit -m "求 Star 弹窗摘掉鲸鱼贴纸，弹窗框架保留

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 5: 伙伴小屋（无素材可摘，保留框架）

**结论（用户确认）**：`app/assets/companion/` 是 AGPL 的 stage 舞台框架代码，不是受保护素材；受保护的 Live2D 模型（`whale-girl.zip`，Cubism 专有许可）单独下载、本就不在仓库。`CompanionPixelWhale` 的像素鲸娘兜底在 Task 3 删 `assets/pets/` 声明后已静默为空。对照 xagent-ios：六个文件全保留、pubspec 声明保留、整个 companion 功能（含语音通话背景）原样在。companion 测试已全绿。无改动。

```bash
git add app/lib/ui/companion/companion_stage.dart app/pubspec.yaml app/assets/companion/ app/test/companion/
git commit -m "伙伴小屋摘掉 Live2D 形象，语音通话保留

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

---

### Task 6: 改名 Xagent + 换包名

**Files:**
- Modify: `app/pubspec.yaml`（name/description）、`app/lib/state/app_info.dart`（name/wordmark）、`app/android/app/build.gradle.kts`（applicationId）、`app/android/app/src/main/AndroidManifest.xml`（label 已改，确认）
- Test: 相关引用处

**Interfaces:**
- Consumes: 无。
- Produces: 包名 `com.xcoder.xagent`，显示名 Xagent，pubspec `name: xagent`。

- [ ] **Step 1: 全局搜旧名残留**：`com.xcoder.agentport`、`AgentPort`（代码里的）、`dsh_app`（pubspec name）在哪些地方出现。

- [ ] **Step 2: 改包名与显示名**：build.gradle.kts 的 applicationId、AndroidManifest.xml 的 label（已改）、app_info.dart 的 name/wordmark、pubspec.yaml 的 name/description。

- [ ] **Step 3: 全局确认无旧包名硬编码残留**：`${applicationId}` 派生值跟着变，不能有新写死的旧包名。

- [ ] **Step 4: 跑 analyze + 相关测试**

- [ ] **Step 5: 提交**

```bash
git add app/pubspec.yaml app/lib/state/app_info.dart app/android/app/build.gradle.kts app/android/app/src/main/AndroidManifest.xml
git commit -m "统一为 Xagent：包名、显示名、pubspec name 全换

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```

**实际执行说明**：包名 `com.xcoder.agentport → com.xcoder.xagent`（18 处，含 6 个 Kotlin 自己包名常量）；显示名 `app_info.name/wordmark` 改 Xagent；约 60 个 ARB 源里的 AgentPort/DSH Go 统一成 Xagent，重新生成 l10n，`--check` 通过；Kotlin 应用名字符串（通知/相册/快捷方式标签/提示前缀）和 strings 中英同步；测试里期望的过时 `DSH Go` 断言改成 Xagent。pubspec `name: dsh_app` **有意保留**——Dart 包名，1366 个 `import 'package:dsh_app/...'`，照 xagent-ios 的参照口径不换。保留一条讲历史的注释（`FilesPlugin.kt`「改名前叫 DSH Go」）。

---

### 未做：鸿蒙（ohos）品牌与包名

鸿蒙这次没动，需要单独一轮，因为它的包名等价物是 `bundleName`，换法跟 Android 的 `applicationId` 不同、影响面也不同。具体残留：

- **显示名**：`EntryAbility_label` 在 `app/ohos/entry/src/main/resources/{base,zh_CN,en_US}/element/string.json` 三处都是 `"DSH Go"`，要改成 Xagent。
- **bundleName**：`app/ohos/AppScope/app.json5` 的 `bundleName` 还是 `ccchimneyyy.dsh.go`，要换成 xagent。换 bundleName 等同换应用，老用户升级会断掉，这点要在动手前明确。
- **启动图标**：`tooling/ohos/make-launcher-icons.py` 读 `app/assets/brand/` 生成鸿蒙 launcher 图标，而 Task 1 已经把 `assets/brand/` 删了——这个脚本现在会因输入缺失而失败，要改指到 Xagent logo 套件（`04_Android/res/` 或 `01_Vector/`）或鸿蒙专属资源。
- **鸿蒙指南**：`docs/guide/harmony/` 里可能还有 DSH Go / AgentPort 的品牌文案，改显示名时要一并同步（双语文档同步是硬规则）。
- **鸿蒙门禁**：改了 `app/ohos/` 必须跑 `tooling/ohos/check-arkts.sh` 和 `run-gates.sh`，这套我在 Android 轮次里没跑。

按用户要求本轮先不动鸿蒙，留待单独处理。

---

### Task 7: 全量验证 + 修挂掉的测试

**Files:**
- Modify: 因删素材而挂的测试文件（brand_mark / activity_strip / pets / star / companion）

- [ ] **Step 1: 全量 flutter test**（按资源预算设并发）
- [ ] **Step 2: 逐个修挂掉的测试**：fixture 里的内置宠物 id 换 `noPetId`，黄金图重新截图，品牌标测试验证 X 形。
- [ ] **Step 3: 全量 flutter analyze**
- [ ] **Step 4: 提交**（如测试修复有独立改动）

```bash
git commit -m "修品牌清理后挂掉的测试

Co-Authored-By: Claude Code <noreply@anthropic.com>"
```
