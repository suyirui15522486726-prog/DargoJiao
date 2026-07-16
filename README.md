# DargoJiao

大狗叫结合用 Codex 把飞书群里的短视频面试链接整理成结构化、可去重、可关联本地项目源码的飞书知识库笔记。是一个轻量级的面试辅助工作流利器。

DargoJiao 是 **Codex Skill + Codex 已安排任务模板**，不是独立爬虫或常驻服务。运行必须使用 ChatGPT/Codex Desktop 和官方 `lark-cli`。默认流程不安装媒体下载器、FFmpeg、本地语音模型、守护进程、数据库或服务器。

`cargo` 负责 Rust，`dargo` 负责把 DargoJiao 装好、查好；真正的视频分析、项目关联和飞书写入仍由 Codex 完成。

## 平台支持

| 平台 | 安装入口 | 验证方式 | 状态 |
|---|---|---|---|
| Windows 10/11 | `.\dargo.cmd install` | Windows GitHub Actions + `.\dargo.cmd doctor` | 原生支持，不要求 WSL |
| macOS | `./dargo install` | 本机验证 + `./dargo doctor` | 支持 |
| Linux | `./dargo install` | Ubuntu GitHub Actions + `./dargo doctor` | 支持 |

## 前置条件

- 已安装并登录 [ChatGPT/Codex Desktop](https://learn.chatgpt.com/docs/quickstart)。
- Git、Node.js/npm 可用。
- 当前飞书账号已经加入输入群，并能编辑目标知识库。
- 电脑能够访问 Codex/OpenAI、GitHub/npm、飞书和目标短视频页面；各链路是否需要代理取决于使用者网络。

Codex 官方说明：Skill 可以为计划任务提供可复用工作流；本地项目计划任务运行时，需要电脑保持开机和唤醒、桌面应用保持运行、本地项目仍在磁盘上。参见 [Build skills](https://learn.chatgpt.com/docs/build-skills) 和 [Scheduled tasks](https://learn.chatgpt.com/docs/automations)。

## 五分钟开始--当然你可以直接交给你的codex无脑部署

1. 按操作系统完成安装和诊断。
2. 准备输入飞书群和目标 Wiki/Docx 的完整链接。
3. 在 Codex 中调用 `$dargojiao` 完成首次配置。
4. 在 Codex「已安排」中手动运行两次，验收写入和去重。

## Windows 原生部署

Windows 版使用系统自带的 Windows PowerShell 5.1，也兼容 PowerShell 7。无需 WSL，不修改用户 PATH。

### 1. 安装基础工具

在 PowerShell 中执行：

```powershell
winget install --id 9PLM9XGG6VKS -s msstore
winget install --id Git.Git
winget install --id OpenJS.NodeJS.LTS
```

关闭并重新打开 PowerShell，确认：

```powershell
git --version
node --version
npm --version
codex --version
```

如果 PowerShell 报“禁止运行脚本”，先阅读微软的执行策略说明。仓库入口 `dargo.cmd` 只对本次受信任脚本调用使用 `-ExecutionPolicy Bypass`，不会修改系统永久执行策略。

### 2. 安装并授权官方飞书 CLI

```powershell
npx @larksuite/cli@latest install
lark-cli config init --new
lark-cli auth login --recommend
lark-cli auth status --json --verify
```

配置和登录会打开浏览器。请使用之后需要读取群聊和编辑知识库的同一个飞书账号授权；浏览器显示成功后，仍要执行最后一条命令确认终端中的用户授权有效。

### 3. 安装 DargoJiao

```powershell
git clone https://github.com/suyirui15522486726-prog/DargoJiao.git
cd DargoJiao
.\dargo.cmd install
.\dargo.cmd doctor
```

安装器只更新 `$HOME\.agents\skills\dargojiao`。测试临时目录时可以设置当前 PowerShell 会话变量：

```powershell
$env:DARGOJIAO_SKILLS_DIR = "$env:TEMP\dargojiao-skills"
.\dargo.cmd install
Remove-Item Env:DARGOJIAO_SKILLS_DIR
```

## macOS 与 Linux 部署

先安装 Node.js/npm、Git、Codex Desktop 和官方飞书 CLI：

```bash
npx @larksuite/cli@latest install
lark-cli config init --new
lark-cli auth login --recommend
lark-cli auth status --json --verify
```

再安装 DargoJiao：

```bash
git clone https://github.com/suyirui15522486726-prog/DargoJiao.git
cd DargoJiao
./dargo install
./dargo doctor
```

直接调用脚本与上面的 `dargo` 命令等价：

```bash
./scripts/install.sh
./scripts/doctor.sh
```

安装器只更新 `$HOME/.agents/skills/dargojiao`。临时测试可以设置 `DARGOJIAO_SKILLS_DIR`，不会覆盖其他 Skill。

## `dargo` 命令

| Windows | macOS/Linux | 作用 |
|---|---|---|
| `.\dargo.cmd install` | `./dargo install` | 幂等安装或升级 Skill |
| `.\dargo.cmd doctor` | `./dargo doctor` | 检查依赖、飞书授权、Skill 和代理提示 |
| `.\dargo.cmd version` | `./dargo version` | 显示版本 |
| `.\dargo.cmd prompt` | `./dargo prompt` | 显示首次配置提示词入口 |
| `.\dargo.cmd help` | `./dargo help` | 显示帮助 |

这些命令不读取飞书消息、不分析视频、不修改知识库，也不会启动后台服务。

## 代理与网络

不要把所有失败都归结为“代理坏了”。DargoJiao 涉及四条独立链路：

| 链路 | 典型现象 | 优先检查 |
|---|---|---|
| Codex/OpenAI | Codex 无法登录或普通对话也失败 | Codex Desktop 自身网络和账号状态 |
| GitHub/npm | clone 或安装 `lark-cli` 超时 | 浏览器能否打开 GitHub、npm，终端是否继承代理 |
| 飞书 OAuth/API | 浏览器授权成功但 CLI 验证失败 | 浏览器与终端是否使用同一网络、授权账号是否正确 |
| 短视频跳转 | 飞书消息能读，但短链无法打开或重定向 | 短视频页面、地区限制、临时风控和代理路由 |

### Windows 只读诊断

```powershell
Get-ChildItem Env:HTTP_PROXY,Env:HTTPS_PROXY -ErrorAction SilentlyContinue
netsh winhttp show proxy
Test-NetConnection github.com -Port 443
Test-NetConnection open.feishu.cn -Port 443
lark-cli auth status --json --verify
```

Windows 系统代理、浏览器扩展代理、WinHTTP 代理和 PowerShell 环境变量可能是四套不同配置。浏览器能打开页面，不代表 PowerShell、`git` 或 `lark-cli` 一定继承相同代理。

只有在你的网络确实需要时，才给当前 PowerShell 会话设置代理；下面地址只是占位示例：

```powershell
$env:HTTP_PROXY = "http://proxy.example:8080"
$env:HTTPS_PROXY = "http://proxy.example:8080"

# 使用结束后清理当前会话
Remove-Item Env:HTTP_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
```

不要把真实代理账号、密码、端口或订阅地址提交到 GitHub Issue、配置示例和日志。代理失效时，链接必须保持“待重试”，不能记录为已处理。

### macOS/Linux 只读诊断

```bash
env | grep -iE '^(http|https)_proxy='
curl -I https://github.com
lark-cli auth status --json --verify
```

系统代理未必自动注入 shell。`./dargo doctor` 只提示 shell 代理状态，不会替你修改代理配置。

## 飞书群与知识库链接

### 输入群

- 配置时优先提供飞书群的准确名称；同名群较多时，让 Codex 列出候选名称和成员数量后再确认。
- 执行 `lark-cli auth login` 的飞书用户必须已入群并能查看历史消息。
- 群里可以有其他成员。DargoJiao 只处理带短视频链接的用户消息，并忽略机器人、系统消息和已撤回消息。

### Wiki 与 Docx

在飞书目标页面点击“分享”或“复制链接”，提供完整 URL，而不是页面标题、截图或单独 token。常见形式：

```text
https://<tenant>.feishu.cn/wiki/<node-token>
https://<tenant>.feishu.cn/docx/<document-token>
```

- Wiki 链接定位知识空间节点，适合让 DargoJiao按 Topic 路由或创建子文档。
- Docx 链接定位具体文档，适合固定写入一个已经准备好的笔记文档。
- URL 中的 `from=...` 等分享参数可以保留；Codex 会先识别链接类型，再解析真实节点。
- OpenAPI 授权通过不等于知识库成员权限通过。授权用户仍必须是目标知识空间成员，并具有查看、创建或编辑权限。
- 学校或企业租户的链接可以正常使用，但不要把真实租户链接复制到公开 Issue、README、日志或截图。

### 短视频分享链接

群消息应包含可点击的原始分享链接，并尽量保留作者和完整标题。只有封面、截图或纯标题时，无法可靠核验视频内容，会标为“待重试”。短链跳转失败、网络失败或证据不足时，不占序号、不写笔记、不写成功标识。

详细配置见 [飞书搭建](docs/feishu-setup.md) 和 [权限边界](docs/permissions.md)。

## 飞书授权

DargoJiao 使用 `lark-cli` 保存的飞书用户授权，仓库不保存凭据。授权过期时重新执行：

```text
lark-cli auth login --recommend
lark-cli auth status --json --verify
```

不要在 Codex 对话、配置文件或 Issue 中粘贴 token、Cookie、应用密钥或浏览器授权回调参数。

## 创建自动化

打开 Codex，选择允许只读分析的本地 Git 项目，然后发送：

```text
使用 $dargojiao 帮我完成首次配置。输入来源是飞书群，输出到飞书知识库；请先检查授权，再创建工作日定时任务，最后带我做一次重复链接验收。
```

Codex 只应询问尚未提供的非敏感配置：群聊名称、Wiki/Docx URL、本地项目路径、Git ref、时区、工作日、执行时间和回看天数。

Skill 会创建或更新一个同名计划任务，不重复创建。自动化每次运行会预检授权和网络、读取回看窗口、三层去重、核验视频证据、生成笔记、按需关联固定 Git ref、路由到 Wiki/Docx、写入后回读，并在 Codex「已安排」中报告结果。

## 首次验收

1. 在输入群发送一个包含作者、标题和短视频原始链接的分享文本。
2. 在 Codex「已安排」中手动运行任务。
3. 检查笔记是否进入正确的 Wiki/Docx，代码是否使用带语言标记的代码块。
4. 再次运行同一任务，确认同一消息和同一视频没有重复笔记。
5. 再转发一次同一视频，确认视频级去重生效。
6. 使用一个没有编辑权限的测试目标运行，确认没有写成功标识；恢复权限后确认可以重试。
7. 临时断开所需网络链路，确认失败项保持待重试且 Codex「已安排」中有明确动作。

可以逐项使用 [首次验收清单](templates/setup-checklist.md)。

## 去重机制

- `svnote-msg:<message_id>`：同一飞书消息只成功处理一次。
- 规范化 URL 与平台视频 ID：同一视频被再次转发时跳过。
- 标题：只作冲突提醒，避免同名视频被误判。

只有写入成功并回读确认后才留下成功标识。证据不足、网络失败、链接错误或权限失败的链接不占序号，保留为待重试。

## 运行结果

Codex「已安排」是唯一运行报告入口，不依赖操作系统弹窗或飞书主动提醒。每次执行都会记录：

- 成功数、跳过数和待重试数。
- 实际写入的 Wiki/Docx 分类。
- 授权、网络、消息、证据、项目、写入或回读失败阶段。
- 不包含凭据和真实资源 ID 的用户修复动作。

## 安全

- 凭据只由 `lark-cli` 管理。
- 本地项目按固定 Git ref 只读，不切换分支、不修改代码。
- 视频证据不足时不猜测、不写笔记、不写成功标识。
- 默认不读取浏览器凭据、不下载视频、不调用外部内容解析服务。
- Issue、日志和示例中不得包含真实群 ID、Wiki/Docx token、租户链接、本地绝对路径、代理地址或凭据。

详见 [安全说明](docs/security.md)。

## 故障排查

先运行当前平台诊断：

```powershell
.\dargo.cmd doctor
```

```bash
./dargo doctor
```

诊断出现 `FAIL` 时按紧随其后的动作修复；`WARN` 表示系统代理可能存在或短视频页面可能临时受限。常见问题详见 [故障排查](docs/troubleshooting.md)。

## 卸载

1. 在 Codex「已安排」中暂停或删除 DargoJiao 任务。
2. 删除用户级 Skill。

Windows：

```powershell
Remove-Item "$HOME\.agents\skills\dargojiao" -Recurse -Force
```

macOS/Linux：

```bash
rm -rf "$HOME/.agents/skills/dargojiao"
```

卸载不会删除已有飞书笔记。

## 升级

Windows：

```powershell
cd DargoJiao
git pull --ff-only
.\dargo.cmd install
.\dargo.cmd doctor
```

macOS/Linux：

```bash
cd DargoJiao
git pull --ff-only
./dargo install
./dargo doctor
```

升级只替换 DargoJiao 自己的 Skill 目录。规则变化时，再用 `$dargojiao` 更新同名计划任务。

## License

[MIT](LICENSE)
