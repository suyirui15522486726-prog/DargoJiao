---
name: dagojiao
description: Use when a user wants to configure, run, troubleshoot, or share a Codex workflow that turns Feishu group short-video links into deduplicated interview notes in Feishu Wiki.
---

# DaGoJiao

把 Codex 作为执行主体，把飞书群中的短视频分享链接整理为可核验、可去重、可关联本地项目的面试笔记。

## 选择模式

- 用户提出“安装、配置、授权、创建定时任务”时，执行“首次配置”。
- 用户提出“现在整理、补跑、重试、检查结果”时，执行“处理链接”。
- 用户报告登录失效、网络失败、重复笔记或写入失败时，读取 `references/troubleshooting.md`。

## 首次配置

1. 读取并遵守 `lark-shared`、`lark-im`、`lark-wiki`、`lark-doc` 的当前说明。飞书操作统一使用用户身份；不要向用户索要明文 token、Cookie 或应用密钥。
2. 检查 `codex`、`lark-cli`、Git、本 Skill 和飞书授权。授权无效时，引导用户完成 `lark-cli` 用户登录，然后重新验证。
3. 只收集缺失的非敏感配置：群聊名称、Wiki URL、本地项目路径、Git ref、时区、工作日、执行时间和回看天数。
4. 解析群聊和知识库，验证群消息读取、Wiki 读取以及 Docx 编辑权限。区分 OpenAPI 权限与知识库成员权限。
5. 读取 `templates/automation-prompt.md`，替换全部命名占位符。
6. 使用 `automation_update` 查找同名任务。存在时更新；不存在时只创建一个任务。任务关联需要只读分析的本地项目。
7. 手动运行一次测试，再重复运行一次，确认笔记只出现一次。

## 处理链接

1. 先做授权、网络、群读取、Wiki 读取和文档写入预检。失败时执行异常报告，不推进处理状态。
2. 完整分页读取回看窗口内的用户消息，忽略机器人、系统消息和已撤回消息。
3. 按 `references/deduplication.md` 做处理前检查；已处理的视频直接计入跳过数。
4. 优先读取原链接。页面受限时，只能按分享文本中的作者和精确标题查找同一作品或可信镜像。证据不足时保留为待重试，不生成笔记。
5. 按 `references/note-format.md` 生成面试笔记。拿不到视频逐字证据时，把错误回答明确标为“反例归纳”。
6. 只读检查配置的本地项目与固定 Git ref。只有知识点与真实代码直接相关时，才加入项目路径、符号和代码块；不要切换分支或修改工作区。
7. 根据 Topic 路由到最合适的 Wiki 文档；没有合适分类时才创建顶层 Docx。
8. 写入后回读，验证唯一标识仅出现一次，再计入成功数。
9. 在 Codex 已安排任务结果中输出成功数、跳过数、待重试数、分类和异常。飞书可用时发送简短群回执；异常时尽力发送 macOS 通知。

## 必须保持的边界

- 不把标题相同直接当成同一视频；标题只用于冲突提醒。
- 不在证据不足时猜测视频观点，也不写成功标识。
- 不复制个人飞书标识、本地绝对路径、代理地址或凭据到文档、日志和回执。
- 不安装媒体下载器、转码器、本地语音模型、常驻服务或数据库。
- 不删除或重排无关知识库内容。

## 参考文件

- 笔记结构与飞书排版：`references/note-format.md`
- 三层去重与重试语义：`references/deduplication.md`
- 故障分类和用户动作：`references/troubleshooting.md`
- 可直接用于 Codex 已安排任务的模板：`templates/automation-prompt.md`

