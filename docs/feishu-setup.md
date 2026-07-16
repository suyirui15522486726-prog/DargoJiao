# 飞书搭建

## 安装官方 CLI

DaGoJiao 使用 [larksuite/cli](https://github.com/larksuite/cli) 操作飞书，不要求部署自己的机器人服务器。

```bash
npx @larksuite/cli@latest install
lark-cli config init --new
lark-cli auth login --recommend
lark-cli auth status --json --verify
```

`config init --new` 用于完成应用配置，`auth login --recommend` 用当前飞书账号完成用户授权。浏览器步骤必须由用户本人确认，不要把验证码、授权 URL 中的敏感参数或凭据发送到公开 Issue。

## 准备输入群

1. 创建或选择一个飞书群，例如“短视频面试笔记”。
2. 确认运行 `lark-cli` 的账号已经入群并能查看历史消息。
3. 群内只需发送抖音分享文本和链接，不需要上传视频文件。
4. 建议保留分享文本中的作者和标题，链接受限时 Codex 会用它们核验同一作品。

群可以有其他成员。DaGoJiao 默认忽略机器人、系统消息和已撤回消息，只处理带链接的用户消息。

## 准备知识库

1. 创建或选择一个飞书知识空间。
2. 把当前用户加入知识空间，并授予创建或编辑文档的权限。
3. 按主题预先创建文档是可选的；DaGoJiao 会优先路由到现有分类，没有合适分类时才创建顶层 Docx。
4. 复制 Wiki URL 交给 Codex，不要把 URL 提交到公开仓库。

## 权限验证

让 `$dagojiao` 在首次配置时完成四项预检：

- 能找到目标群并读取一页历史消息。
- 能读取目标 Wiki 的顶层节点。
- 能读取目标 Docx 正文。
- 能在测试文档中追加并回读一段无敏感信息的内容。

完成测试后可以删除测试段落。不要直接在正式文档中做权限破坏性实验。

