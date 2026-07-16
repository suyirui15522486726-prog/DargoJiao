# DargoJiao v0.2.0 Windows 兼容与更名设计

## 背景

DargoJiao 是一个由 Codex Desktop 驱动的飞书短视频面试笔记工作流。现有版本已经提供 Codex Skill、飞书授权说明、定时任务模板、去重和项目源码关联，但安装、诊断和通知说明以 macOS 为主。

v0.2.0 将项目全面更名为 DargoJiao，并增加经过 Windows CI 验证的原生 PowerShell 部署路径。现有 v0.1.0 Release 和 Git 历史继续保留；当前分支、后续 Release 和 GitHub 仓库名称使用 DargoJiao。

## 目标

1. Windows 10/11 用户不安装 WSL 也能完成 Skill 安装、环境诊断、飞书授权和 Codex 已安排任务配置。
2. macOS/Linux 的 Bash 安装路径继续可用。
3. 当前文件、脚本、测试、提示词和展示文案统一使用 DargoJiao。
4. Skill 调用名统一为 `$dargojiao`，用户级安装目录为 `$HOME/.agents/skills/dargojiao`。
5. 删除操作系统弹窗和主动飞书提醒，只以 Codex「已安排」运行结果作为异常与成功报告。
6. README 给出可复制的 Windows 部署、代理、飞书链接、权限和验收步骤。
7. Windows GitHub Actions 必须真实执行 PowerShell 安装、重复安装和诊断测试后，才发布 v0.2.0。

## 非目标

- 不实现短视频下载器、FFmpeg、本地语音模型或第三方内容解析服务。
- 不实现常驻进程、数据库、Web 服务或独立 AI 运行时。
- 不要求 WSL，不修改 Windows 用户 PATH，不安装系统通知依赖。
- 不把 `dargo` 发布成 npm、Cargo、PyPI 或系统包。
- 不保证外部短视频页面、飞书服务或代理节点永久可用；诊断和重试语义必须明确。

## 命名与兼容策略

当前版本统一使用：

| 对象 | v0.2.0 名称 |
|---|---|
| 产品和 GitHub 仓库 | `DargoJiao` |
| Skill 名 | `dargojiao` |
| Codex 显式调用 | `$dargojiao` |
| Skill 安装目录 | `.agents/skills/dargojiao` |
| 环境变量 | `DARGOJIAO_SKILLS_DIR` |
| 趣味命令 | `dargo` |
| Release | `v0.2.0` |

不修改或删除 v0.1.0 Tag、Release 和历史提交，不对旧版本做 force-push。GitHub 仓库更名后依赖 GitHub 的旧地址重定向；v0.2.0 当前文件不保留旧 Skill 别名，避免同名工作流并存和触发歧义。

## 平台方案

### macOS 与 Linux

- 保留 `scripts/install.sh` 和 `scripts/doctor.sh`。
- 提供仓库内 `./dargo install|doctor|version|prompt|help` 薄命令。
- Bash 脚本继续使用严格模式和临时目录替换，重复执行保持幂等。

### Windows 原生 PowerShell

- 新增 `scripts/install.ps1`，兼容 Windows PowerShell 5.1 及 PowerShell 7。
- 新增 `scripts/doctor.ps1`，检查 Git、Codex、Node/npm、`lark-cli`、飞书用户授权、Skill 安装、本地项目和代理提示。
- 新增 `dargo.cmd`，将 `install`、`doctor`、`version`、`prompt` 和 `help` 分发给 PowerShell 脚本。
- 用户从仓库根目录执行 `.\dargo.cmd <command>`，不写入系统目录、不修改 PATH。
- 安装器只操作 `.agents/skills/dargojiao`，写入前使用临时目录，替换失败时恢复备份。

## `dargo` 命令边界

`dargo` 是轻量入口，不负责 AI 分析和定时调度：

| 命令 | 行为 |
|---|---|
| `dargo install` | 调用当前平台安装脚本 |
| `dargo doctor` | 调用当前平台诊断脚本 |
| `dargo version` | 输出 `DargoJiao v0.2.0` |
| `dargo prompt` | 输出首次配置提示词的位置和调用方式 |
| `dargo help` | 输出命令帮助 |

未知命令返回非零状态并显示帮助。命令不读取飞书消息、不修改知识库、不启动后台服务。

## 运行结果与通知

- 自动化每次运行必须在 Codex「已安排」中报告时间、成功数、跳过数、待重试数、分类和异常动作。
- 删除 macOS 通知中心、Windows Toast 和主动飞书群回执。
- 飞书授权失效时，任务仍能在 Codex「已安排」中留下错误阶段和重新授权命令。
- 删除通知能力不能改变去重规则：只有文档写入并回读成功后才记录成功标识。

## Windows README 部署流程

README 增加独立的 Windows 章节，按以下顺序组织：

1. 安装 ChatGPT/Codex Windows 桌面应用、Git 和 Node.js LTS。
2. 从 PowerShell 克隆 DargoJiao。
3. 安装和配置官方 `lark-cli`，完成浏览器用户授权。
4. 执行 `.\dargo.cmd install` 和 `.\dargo.cmd doctor`。
5. 在 Codex 中使用 `$dargojiao` 完成首次配置。
6. 在「已安排」中手动运行一次。
7. 验证正常写入、重复链接跳过和异常结果可见。

README 同时说明：计划任务运行时电脑必须开机、Codex Desktop 必须运行、本地项目仍需存在，Windows 睡眠会阻止本地任务执行。

## 代理与网络说明

文档把网络分成四条链路，避免把所有问题统称为“网络不好”：

1. Codex/OpenAI：确认桌面应用能够登录并执行普通任务。
2. GitHub/npm：确认能够克隆仓库并安装 `lark-cli`。
3. 飞书：确认浏览器和终端使用同一可用网络，OAuth 登录完成后运行 `lark-cli auth status --json --verify`。
4. 短视频页面：确认分享链接可以跳转；临时受限时保留为待重试，不占序号、不写成功标识。

Windows 章节提供以下只读诊断命令：

```powershell
Get-ChildItem Env:HTTP_PROXY,Env:HTTPS_PROXY -ErrorAction SilentlyContinue
netsh winhttp show proxy
Test-NetConnection github.com -Port 443
Test-NetConnection open.feishu.cn -Port 443
lark-cli auth status --json --verify
```

说明系统代理、浏览器代理和 PowerShell 环境变量可能不是同一配置。只在用户确实需要时设置当前会话的 `HTTP_PROXY`/`HTTPS_PROXY`，示例使用占位地址，不写真实代理端口、账号或密码。代理故障不得被判定为视频已处理。

## 飞书链接与权限说明

README 和飞书搭建文档必须区分：

- 输入来源是飞书群名称或群聊标识，运行身份必须已入群并能读取历史消息。
- 输出目标使用从飞书“复制链接”获得的完整 Wiki 或 Docx URL，不接受页面标题、浏览器截图或只复制 token。
- Wiki URL 用于定位知识空间和节点；Docx URL 用于定位具体文档。工作流先解析链接类型，再选择 Wiki 或 Docx 操作。
- “API 授权成功”不等于“知识库成员权限成功”。当前飞书用户仍需在目标知识空间拥有查看和编辑权限。
- 抖音分享内容必须包含可点击原始链接；只有封面、截图或纯标题时证据不足，标记待重试。
- 不在 GitHub Issue、日志、README 示例或截图中公开真实群 ID、Wiki token、Docx token、租户域名、本机路径、Cookie 或代理凭据。

首次验收必须覆盖：正确 Wiki/Docx 路由、代码块格式、重复链接不重复生成、无权限时不写成功标识、授权恢复后可重试。

## 测试与 CI

### 先写失败测试

在实现 PowerShell 和更名之前，先扩展仓库测试，要求：

- 所有必需 Windows 文件存在。
- 当前文件中不存在旧产品名、旧 Skill 名和旧环境变量。
- README 包含 Windows 原生部署、代理、飞书链接和权限说明。
- 自动化提示词不包含任何操作系统通知或主动群提醒。
- POSIX 与 Windows 的自动化提示词副本一致。
- `dargo` 的帮助、版本、未知命令和分发入口符合约定。

测试必须先因缺少实现而失败，再新增最小实现使其通过。

### GitHub Actions

新增轻量 CI：

- Ubuntu：运行 Python 仓库校验、Bash 语法检查、`dargo` 命令测试和临时目录双次安装。
- Windows：运行 Python 仓库校验、PowerShell 解析、`dargo.cmd` 命令测试和临时目录双次安装。
- Windows 诊断测试使用测试期临时命令替身，不访问真实飞书账号、不读取任何用户凭据。

发布前必须看到 Windows Job 和 Ubuntu Job 都成功。macOS 继续使用本机完成 Bash 与真实飞书授权诊断，不为此增加付费 macOS CI。

## 错误处理

- 缺少 Git、Codex、Node/npm 或 `lark-cli`：诊断返回失败并给出单一修复动作。
- 飞书授权缺失或过期：停止写入，报告重新登录命令，保留待重试。
- Skill 安装失败：恢复旧目标目录，返回非零状态。
- Wiki/Docx 链接类型无法识别：不猜测目标，不写文档。
- 知识库权限不足：不降级到其他文档，不写成功标识。
- 短视频证据不足或重定向失败：不生成猜测性笔记，保持待重试。
- 未知 `dargo` 子命令：显示帮助并返回非零状态。

## 发布步骤

1. 在功能分支完成设计、测试和实现。
2. 推送分支并让 GitHub Actions 在 Ubuntu 与 Windows 上通过。
3. 合并到 `main`。
4. 将 GitHub 仓库更名为 `DargoJiao`。
5. 从更名后的远端重新核验 README、分支、Release 和链接重定向。
6. 创建并发布 `DargoJiao v0.2.0`，保留 v0.1.0。

## 验收标准

- Windows 用户按照 README，从空环境可走到 `$dargojiao` 首次配置入口。
- `.\dargo.cmd install` 连续执行两次均成功且只更新 DargoJiao Skill 目录。
- `.\dargo.cmd doctor` 能区分依赖、授权、权限提示和代理提示。
- Windows GitHub Actions 真实运行 PowerShell 脚本并通过。
- 当前 `main` 的文本和代码统一使用 DargoJiao/dargojiao/dargo 新命名。
- 自动化不依赖任何系统弹窗或飞书主动提醒。
- README 对代理、短链接、Wiki/Docx 链接、知识库成员权限和待重试语义给出可操作说明。
- v0.1.0 Release 保留，v0.2.0 在更名后的公开仓库可访问。
