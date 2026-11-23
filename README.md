<p align="center">
  <b>简体中文</b> · <a href="README.en.md">English</a>
</p>

<p align="center">
  Xagent-Android：Android 端 AI 编程与 Agent 托管应用
</p>

<p align="center">
  本项目借鉴开源项目 <a href="https://github.com/ccch1mneyyy/dsh-go">dsh-go</a> 的思路实现：
  在手机上运行 Linux 环境内的 DSH 引擎（免 Root、免 Termux），同时支持 SSH / 远程主机连接，
  并在 App 内提供原生聊天界面、插件界面与手机操控能力。
  模型请求仍由你配置的模型提供方处理。
</p>

## 可以做什么

- **本机运行**：在 App 内安装 Ubuntu、Node.js 与 DSH 运行环境，无需 Root 或另装 Termux。
- **远程连接**：通过 SSH 使用电脑、服务器上的 DSH。
- **聊天与工具**：切换模型，发送图片、使用语音输入，处理工具审批和提问；支持聊天界面与网页模式。
- **插件界面**：使用适配的原生工具卡、表单和面板；仓库提供 SDK、教程和示例。
- **手机操控**：在开启权限后，让本机引擎读取屏幕、点按和输入，并可随时停止。
- **分享与外观**：分享、导出和回放对话，调整主题与图标。

## 安装

安装要求为 Android 8.0（API 26）及以上。从 Releases 页面下载对应架构的 APK（常见手机选 arm64 包），
按系统提示允许安装来源；首次启动时选择本机运行环境或远程主机，配置模型与凭据后开始对话。

仅连接远程主机时，不必在手机上安装本机运行环境。手机操控只对正常模式下的本机引擎开放，
需要按界面说明开启无障碍等权限。首次使用可按[使用指南](docs/guide/README.md)逐项配置。

## 数据与权限

模型请求会发送给你配置的提供方。开启手机操控后，任务需要的屏幕文字可能发送给模型，
支持看图的模型也可能收到截图；请先阅读 App 的权限说明。

“发送匿名使用统计”默认开启，可在首次引导或“设置 → 隐私与分享”关闭。

## 风险提示与免责声明

本项目为非官方社区项目。AI 回答、代码和操作可能出错，也可能被外部内容中的恶意指令误导；
本机或远程主机上的命令、文件修改及手机操控可能导致数据丢失、隐私泄露等真实影响。
建议保留默认保护，只授予必要权限，备份重要数据，只连接可信主机、安装可信插件。
本软件按“现状”提供，无担保；详见 [LICENSE](LICENSE) 相关条款。

## 从源码构建

以下流程面向 Linux x86_64：准备 JDK 17、Flutter 3.47.7 与 Android SDK/NDK，
App 要求 Dart `^3.13.5`。

```bash
bash tooling/setup-toolchain.sh
source tooling/env.sh

bash runtime/build-runtime.sh arm64-v8a
DSH_BETA_TOKEN_FILE= bash tooling/build-apk.sh -f arm64 --keep-daemon
```

产物为 `app/build/app/outputs/flutter-apk/app-arm64-release.apk`。
完整说明与 x86_64 构建见下方各目录的 README。

## 目录

| 路径 | 内容 |
| --- | --- |
| `app/` | Flutter 界面与 Android Kotlin 实现 |
| `packages/dsh_client/` | DSH Web API 的 Dart 客户端 |
| `packages/dsh_remote/` | DSH Remote 的 Dart 客户端 |
| `runtime/` | Android Linux 运行时、引擎补丁与 App 桥接 |
| `sdk/plugin-kit/` | 原生插件作者工具包 |
| `examples/plugins/` | 插件示例 |
| `docs/guide/` | 用户指南 |
| `tooling/` | 工具链与构建脚本 |

## 参与贡献

问题反馈和改进建议可提交到 Issues。代码与文档贡献请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 授权与致谢

本项目代码以 [AGPL-3.0](LICENSE) 开源，`sdk/` 和 `examples/` 为 MIT。

本项目借鉴 [dsh-go](https://github.com/ccch1mneyyy/dsh-go)（AGPL-3.0）的实现思路，
向其作者表示谢意；DeepSeek Harness、DSH Remote 及其他第三方组件保留各自的许可证与署名，
见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
