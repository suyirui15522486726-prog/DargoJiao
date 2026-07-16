# 飞书搭建

## 安装官方 CLI

DargoJiao 使用 [larksuite/cli](https://github.com/larksuite/cli) 操作飞书，不要求部署自己的机器人服务器。

```text
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

群可以有其他成员。DargoJiao 默认忽略机器人、系统消息和已撤回消息，只处理带链接的用户消息。

## 准备知识库

1. 创建或选择一个飞书知识空间。
2. 把完成 `lark-cli auth login` 的当前用户加入知识空间，并授予创建或编辑文档的权限。
3. 在目标页面使用飞书“分享”或“复制链接”，不要只复制标题、截图或 token。
4. Wiki 和 Docx 是不同目标类型：

```text
https://<tenant>.feishu.cn/wiki/<node-token>
https://<tenant>.feishu.cn/docx/<document-token>
```

- Wiki URL 用于定位知识空间节点，适合按 Topic 路由或创建子文档。
- Docx URL 用于定位一个固定文档，适合所有笔记写入同一页面。
- `from=...` 等分享参数可以保留；Codex 应先识别链接类型，再解析实际节点。
- 按主题预先创建文档是可选的；没有合适分类时才创建顶层 Docx。

真实租户 URL、Wiki token 和 Docx token 只在私有 Codex 配置对话中提供，不要提交到公开仓库、Issue、日志或截图。

## 权限验证

让 `$dargojiao` 在首次配置时完成四项预检：

- 能找到目标群并读取一页历史消息。
- 能读取目标 Wiki 的顶层节点。
- 能读取目标 Docx 正文。
- 能在测试文档中追加并回读一段无敏感信息的内容。

完成测试后可以删除测试段落。不要直接在正式文档中做权限破坏性实验。

如果浏览器能打开链接但 CLI 仍然无权访问，先核对浏览器账号与 `lark-cli` 当前账号是否一致，再检查知识空间成员权限。OpenAPI 授权成功不代表资源成员权限成功。
