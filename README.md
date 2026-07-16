# DaGoJiao

大狗叫结合用 Codex 把飞书群里的短视频面试链接整理成结构化、可去重、可关联本地项目源码的飞书知识库笔记。是一个轻量级的面试辅助工作流利器。

DaGoJiao 是 **Codex Skill + Codex 已安排任务模板**，不是独立爬虫或常驻服务。运行必须使用 Codex Desktop 和官方 `lark-cli`。默认流程不安装媒体下载器、FFmpeg、本地语音模型、守护进程、数据库或服务器。

## 前置条件

- macOS 上已安装并登录 [Codex Desktop](https://learn.chatgpt.com/docs/quickstart)。
- Git 与 Node.js/npm 可用。
- 能访问飞书、目标短视频页面和必要的公开检索页面。
- 当前飞书账号已经加入输入群和目标知识库。

Codex 官方说明：Skill 可以为计划任务提供可复用工作流；本地项目计划任务运行时，需要电脑保持开机、桌面应用运行且项目仍在磁盘上。参见 [Build skills](https://learn.chatgpt.com/docs/build-skills) 和 [Scheduled tasks](https://learn.chatgpt.com/docs/automations)。

## 五分钟开始--当然你可以直接交给你的codex无脑部署

### 1. 安装并登录官方飞书 CLI

```bash
npx @larksuite/cli@latest install
lark-cli config init --new
lark-cli auth login --recommend
lark-cli auth status --json --verify
```

配置和登录过程中会打开浏览器，需要你使用自己的飞书账号确认。官方安装说明见 [larksuite/cli](https://github.com/larksuite/cli)。

### 2. 安装 DaGoJiao Skill

```bash
git clone https://github.com/suyirui15522486726-prog/DaGoJiao.git
cd DaGoJiao
./scripts/install.sh
./scripts/doctor.sh
```

安装器只更新 `$HOME/.agents/skills/dagojiao`。如需测试到临时位置，可设置 `DAGOJIAO_SKILLS_DIR`。

### 3. 让 Codex 完成配置

打开 Codex，选择一个允许只读分析的本地 Git 项目，然后发送：

```text
使用 $dagojiao 帮我完成首次配置。输入来源是飞书群，输出到飞书知识库；请先检查授权，再创建工作日定时任务，最后带我做一次重复链接验收。
```

Codex 只会询问群聊名称、Wiki URL、本地项目路径、Git ref、时区、工作日、执行时间和回看天数。不要在对话中粘贴 token、Cookie 或应用密钥。

## 飞书授权

DaGoJiao 使用 `lark-cli` 保存的飞书用户授权，不在仓库中保存凭据。首次使用需要完成应用配置和用户登录；授权过期时重新执行：

```bash
lark-cli auth login --recommend
lark-cli auth status --json --verify
```

接口权限通过不代表知识库成员权限已经通过。账号还必须能看到目标群历史消息，并在目标知识空间中拥有创建或编辑文档的权限。详见 [飞书搭建](docs/feishu-setup.md) 和 [权限边界](docs/permissions.md)。

## 创建自动化

Skill 会让 Codex 创建或更新一个独立计划任务，不会为同一工作流反复创建新任务。你可以配置任意本地时间，例如工作日 `09:30`。

自动化每次运行都会：预检授权和网络、读取回看窗口、三层去重、核验视频证据、生成面试笔记、可选关联固定 Git ref、路由到 Wiki、写入后回读验证，并在 Codex「已安排」中生成报告。

详细配置和运行边界见 [Codex 自动化](docs/codex-automation.md)。

## 首次验收

1. 在输入群发送一个带作者、标题和抖音链接的分享文本。
2. 在 Codex「已安排」中手动运行一次任务。
3. 检查笔记是否进入正确分类，代码是否使用代码块。
4. 再运行一次相同任务。
5. 确认同一消息、同一视频和同一编号标题都只出现一次。
6. 暂时撤销一个非关键测试权限并运行，确认「已安排」中出现异常报告；随后恢复权限。

可以逐项使用 [首次验收清单](templates/setup-checklist.md)。

## 去重机制

- `svnote-msg:<message_id>`：同一飞书消息只成功处理一次。
- 规范化 URL 与平台视频 ID：同一视频被再次转发时跳过。
- 标题：只作冲突提醒，避免同名视频被误判。

只有写入成功并回读确认后才留下成功标识。证据不足、网络失败或权限失败的链接不占序号，保留为待重试。

## 异常通知

通知按可靠性排序：

1. Codex「已安排」结果是主要记录，未读标记会提示需要关注的运行。
2. macOS 通知中心是尽力而为的本机提醒。
3. 飞书仍可发送消息时，原群会收到简短回执或异常提醒。

飞书授权本身失效时，不能依赖飞书群通知，请查看 Codex「已安排」。

## 安全

- 凭据只由 `lark-cli` 管理。
- 本地项目按固定 Git ref 只读，不切换分支、不修改代码。
- 视频证据不足时不猜测、不写笔记、不写成功标识。
- 默认不读取浏览器凭据、不下载视频、不调用外部内容解析服务。
- Issue、日志、回执和示例中不得包含真实群 ID、Wiki token、本地绝对路径、代理地址或凭据。

详见 [安全说明](docs/security.md)。

## 故障排查

先运行：

```bash
./scripts/doctor.sh
```

常见问题包括飞书授权过期、知识库成员权限不足、代理暂时不可用、电脑睡眠、短视频页面受限和本地 Git ref 不存在。处理方式见 [故障排查](docs/troubleshooting.md)。

## 卸载

1. 在 Codex「已安排」中暂停或删除 DaGoJiao 任务。
2. 删除用户级 Skill：

```bash
rm -rf "$HOME/.agents/skills/dagojiao"
```

卸载不会删除已有飞书笔记。

## 升级

```bash
cd DaGoJiao
git pull --ff-only
./scripts/install.sh
./scripts/doctor.sh
```

升级安装是幂等的，只替换 DaGoJiao 自己的 Skill 目录。已有计划任务需要更新规则时，在 Codex 中再次发送首次配置提示，Skill 会更新同名任务。

## License

[MIT](LICENSE)

