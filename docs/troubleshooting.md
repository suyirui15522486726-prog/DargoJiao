# 故障排查

先运行当前平台诊断：

```bash
./dargo doctor
```

```powershell
.\dargo.cmd doctor
```

## 找不到 `$dargojiao`

重新安装并重启 Codex。macOS/Linux：

```bash
./dargo install
```

Windows：

```powershell
.\dargo.cmd install
```

确认 `$HOME/.agents/skills/dargojiao/SKILL.md`（Windows 上为 `$HOME\.agents\skills\dargojiao\SKILL.md`）存在。Codex 官方用户级 Skill 目录是 `$HOME/.agents/skills`。

## Windows 无法执行 `dargo.cmd`

- 确认当前目录是仓库根目录，而不是 `scripts` 目录。
- 运行 `Get-Command powershell.exe`，确认 Windows PowerShell 可用。
- 仓库入口只为当前进程使用 `-ExecutionPolicy Bypass`，不会修改永久执行策略。
- 如果公司设备策略阻止 PowerShell，请联系管理员；不要通过关闭安全软件或下载未知脚本绕过。

## 飞书授权失效

```bash
lark-cli auth login --recommend
lark-cli auth status --json --verify
```

授权成功后手动运行一次任务。失败期间没有写入成功标识的链接会保持可重试。

## 找不到群聊

- 核对群聊名称是否完全一致。
- 确认当前授权账号已入群并能查看历史消息。
- 同名群较多时，让 Codex 列出候选群名称和成员数量后再确认，不要把真实群 ID 写入公开配置。

## Wiki 能读不能写

检查当前用户是否是知识空间成员并具有编辑权限。OpenAPI 授权正常不代表资源成员权限正常。

## Wiki/Docx 链接无法识别

- 从飞书目标页面使用“分享”或“复制链接”，提供完整 URL。
- 不要只提供页面标题、截图、Wiki token 或 Docx token。
- 核对路径中是 `/wiki/` 还是 `/docx/`；两者对应不同写入目标。
- 浏览器能打开但 CLI 无权读取时，核对浏览器账号与 `lark-cli` 当前授权账号是否一致。
- 无法确认目标时不要改写到其他文档，保持待重试。

## 网络或代理不稳定

- 分别确认 Codex/OpenAI、GitHub/npm、飞书 OAuth/API 和短视频跳转链路，不要只测试一个网站。
- Windows 可运行 `Get-ChildItem Env:HTTP_PROXY,Env:HTTPS_PROXY`、`netsh winhttp show proxy` 和 `Test-NetConnection open.feishu.cn -Port 443`。
- macOS/Linux 可运行 `env | grep -iE '^(http|https)_proxy='` 并检查系统代理。
- 代理可以使用系统模式或 shell 环境变量；DargoJiao 不强制代理软件、协议或端口。
- 浏览器可用不代表 PowerShell、Git 或 `lark-cli` 继承相同代理。
- 网络失败时任务不应写成功标识。恢复后手动运行或等待下一个工作日。

不要把真实代理地址、端口、账号、密码或订阅链接粘贴到公开 Issue。完整代理说明见 [README 的代理与网络章节](../README.md#代理与网络)。

## 电脑睡眠或错过计划时间

本地任务需要电脑开机并保持唤醒、Codex 运行且项目可读。Windows 合盖、睡眠或休眠同样会阻止任务。唤醒后手动运行一次；如果停机超过默认回看窗口，临时扩大回看天数。

## 视频一直待重试

先查看 Codex「已安排」中的具体原因：

- 公开页只有作品 ID、没有正文或字幕：这不应待重试。只要分享标题能表达清晰题目，DargoJiao 应继续生成笔记，并标注“反例归纳/技术事实整理”。
- 无法解析作品 ID、题目不明确或作者/标题与解析结果冲突：保留完整分享文本和原始链接，等待下次补处理。
- 技术事实、权限、网络、写入或回读失败：修复对应依赖后手动运行，或等待下一个工作日重新扫描。

如果运行结果仅写“公开页没有正文或字幕”就拒绝处理，说明自动化仍使用旧提示词；重新使用 `$dargojiao` 更新同名计划任务。

## 出现重复笔记

1. 搜索 `svnote-msg:<message_id>` 是否出现多次。
2. 检查同一视频的规范化 URL 和平台视频 ID。
3. 暂停重复的计划任务，只保留一个。
4. 不要直接删除全部笔记；先确定哪一条包含正确唯一键。

## 没有看到运行结果

打开 Codex「已安排」，检查任务是否启用、是否到达执行时间以及最近一次运行是否失败。本工作流不依赖操作系统弹窗或飞书主动提醒。
