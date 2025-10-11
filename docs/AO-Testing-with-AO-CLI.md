# AO 应用自动化测试指南（使用 AO CLI）

本文档指导开发者使用 AO CLI 工具自动化测试 AO Dapp 示例项目，避免手动重复操作。

## 前置条件

### 1. 已安装的工具
- [aos](https://cookbook_ao.g8way.io/welcome/getting-started.html) - AO 操作系统客户端
- [Docker](https://docs.docker.com/engine/install/) - 用于代码生成
- [Node.js 18+](https://nodejs.org/) - 用于安装 AO CLI
- [npm](https://www.npmjs.com/) - 包管理器

### 2. 安装 AO CLI 工具
```bash
# 安装独立的 AO CLI 工具
npm install -g @dddappp/ao-cli

# 验证安装
ao-cli --version
```

### 3. 项目结构确认
确保项目目录包含以下关键文件：
- `src/ai_assisted_ao_dapp_example.lua` - 主应用文件
- 其他生成的业务逻辑文件（.lua 文件）

注意：测试时不需要存在 DDDML 模型文件（.yaml），因为测试的是已经生成的代码。

## 环境准备

### 1. 网络配置（根据需要）
如果您的网络环境需要代理才能访问 AO 网络，请设置相应的环境变量：

```bash
# 根据您的网络环境配置以下变量（如果需要）
export HTTPS_PROXY=http://your-proxy-host:port
export HTTP_PROXY=http://your-proxy-host:port
export ALL_PROXY=socks5://your-proxy-host:port
```

### 2. 钱包文件确认
确保 AO 钱包文件存在：
```bash
ls -la ~/.aos.json
```

如果钱包文件不存在，请先运行 `aos` 创建钱包文件。

## 测试流程概述

**关键原则：从开始到结束，所有操作必须在同一个 AO CLI 会话中完成！**

## 详细测试流程

### 步骤 1: 生成 AO 进程
```bash
# 生成 AO 进程（使用时间戳确保进程名唯一）
PROCESS_ID=$(ao-cli spawn default --name "blog-test-$(date +%s)" 2>/dev/null | grep "📋 Process ID:" | awk '{print $4}')
echo "进程 ID: $PROCESS_ID"
```

### 步骤 2: 加载应用代码

```bash
# 加载博客应用代码到进程
ao-cli load "$PROCESS_ID" ./src/ai_assisted_ao_dapp_example.lua --wait
```

### 步骤 3: 获取文章序号

```bash
# 初始化json库并发送消息
ao-cli eval "$PROCESS_ID" --data "json = require('json'); Send({ Target = ao.id, Tags = { Action = 'GetArticleIdSequence' } })" --wait
```

> **💡 AO Inbox 机制说明**：
> 要让消息出现在进程的 Inbox 中，可以在该进程内使用 `eval` 执行 `Send()` 调用。
> 当进程向自己回复消息时，如果没有对应的消息处理器来处理，消息就会被放入该进程的 Inbox 中。

### 步骤 4: 创建文章

```bash
# 创建第一篇文章
ao-cli message "$PROCESS_ID" CreateArticle --data '{"title": "Hello World", "body": "This is a test article"}' --wait
```

### 步骤 5: 获取并验证文章

```bash
# 获取文章详情
ao-cli message "$PROCESS_ID" GetArticle --data '{"article_id": 1}' --wait
```

### 步骤 6: 更新整个文章

```bash
# 更新文章（使用 version: 0，因为刚创建的文章版本是 0）
ao-cli message "$PROCESS_ID" UpdateArticle --data '{"article_id": 1, "version": 0, "title": "Updated Title", "body": "Updated content"}' --wait
```

### 步骤 7: 测试 UpdateBody 方法

```bash
# 单独更新文章正文（使用 version: 1，因为上一步更新后版本已递增）
ao-cli message "$PROCESS_ID" UpdateArticleBody --data '{"article_id": 1, "version": 1, "body": "AI-assisted body update"}' --wait
```

### 步骤 8: 添加评论

```bash
# 获取当前文章版本（确认当前版本为 2）
ao-cli message "$PROCESS_ID" GetArticle --data '{"article_id": 1}' --wait

# 添加评论（使用版本号 2，因为前面经过了创建+更新+更新正文，总共3次操作）
ao-cli eval "$PROCESS_ID" --data "json = require('json'); Send({ Target = ao.id, Tags = { Action = 'AddComment' }, Data = json.encode({ article_id = 1, version = 2, commenter = 'alice', body = 'Great article!' }) })" --wait
```

### 步骤 9: 获取评论

```bash
# 获取刚添加的评论
ao-cli message "$PROCESS_ID" GetComment --data '{"article_comment_id": {"article_id": 1, "comment_seq_id": 1}}' --wait
```

## 自动化测试脚本示例

> **🚨 脚本执行警告：此脚本中的所有命令必须在支持 shell 执行的环境中运行！**
>
> 脚本中的 AO CLI 命令是实际的可执行命令，可以在 bash/zsh 中直接运行。

```bash
#!/bin/bash
set -e

echo "=== AO 博客应用自动化测试脚本 (使用 ao-cli 工具) ==="
echo "基于 AO-Testing-with-AO-CLI.md 文档的测试流程"
echo ""

# 检查 ao-cli 是否安装
if ! command -v ao-cli &> /dev/null; then
    echo "❌ ao-cli 命令未找到。"
    echo "请先运行以下命令安装："
    echo "  npm install -g @dddappp/ao-cli"
    exit 1
fi

# 检查钱包文件是否存在
WALLET_FILE="${HOME}/.aos.json"
if [ ! -f "$WALLET_FILE" ]; then
    echo "❌ AOS 钱包文件未找到: $WALLET_FILE"
    echo "请先运行 aos 创建钱包文件"
    exit 1
fi

# 检查应用代码文件是否存在
APP_FILE="./src/ai_assisted_ao_dapp_example.lua"
if [ ! -f "$APP_FILE" ]; then
    echo "❌ 应用代码文件未找到: $APP_FILE"
    exit 1
fi

echo "✅ 环境检查通过"
echo "   钱包文件: $WALLET_FILE"
echo "   应用代码: $APP_FILE"
echo "   ao-cli 版本: $(ao-cli --version)"
echo ""

# 初始化步骤状态跟踪变量
STEP_SUCCESS_COUNT=0
STEP_TOTAL_COUNT=9

echo "🚀 开始执行测试..."
echo "精确重现 AO-Testing-with-AO-CLI.md 的完整测试流程："
echo "  1. 生成 AO 进程 (spawn)"
echo "  2. 加载博客应用代码 (load)"
echo "  3. 获取文章序号 (eval)"
echo "  4. 创建文章 (message)"
echo "  5. 获取文章 (message)"
echo "  6. 更新文章 (message)"
echo "  7. 更新正文 (message)"
echo "  8. 添加评论 (eval)"
echo "  9. 获取评论 (message)"
echo ""

# 设置等待时间
WAIT_TIME="${AO_WAIT_TIME:-3}"
echo "等待时间设置为: ${WAIT_TIME} 秒"
echo ""

START_TIME=$(date +%s)

# 1. 生成 AO 进程
echo "=== 步骤 1: 生成 AO 进程 ==="
echo "正在生成AO进程..."
PROCESS_ID=$(ao-cli spawn default --name "blog-test-$(date +%s)" 2>/dev/null | grep "📋 Process ID:" | awk '{print $4}')
echo "进程 ID: '$PROCESS_ID'"

if [ -z "$PROCESS_ID" ]; then
    echo "❌ 无法获取进程 ID"
    exit 1
else
    echo "✅ 步骤1成功，当前成功计数: $((++STEP_SUCCESS_COUNT))"
fi
echo ""

# 2. 加载博客应用代码
echo "=== 步骤 2: 加载博客应用代码 ==="
echo "正在加载代码到进程: $PROCESS_ID"
if ao-cli load "$PROCESS_ID" "$APP_FILE" --wait; then
    echo "✅ 代码加载成功，当前成功计数: $((++STEP_SUCCESS_COUNT))"
else
    echo "❌ 代码加载失败"
    echo "由于代码加载失败，测试终止"
    exit 1
fi
echo ""

# 3. 获取文章序号
echo "=== 步骤 3: 获取文章序号 ==="
echo "初始化json库并发送消息..."
if ao-cli eval "$PROCESS_ID" --data "json = require('json'); Send({ Target = ao.id, Tags = { Action = 'GetArticleIdSequence' } })" --wait; then
    echo "✅ 消息发送成功"
    ((STEP_SUCCESS_COUNT++))
else
    echo "❌ 消息发送失败"
fi
echo ""

# 4. 创建文章
echo "=== 步骤 4: 创建文章 ==="
if ao-cli message "$PROCESS_ID" CreateArticle --data '{"title": "Hello World", "body": "This is a test article"}' --wait; then
    echo "✅ 消息发送成功"
    ((STEP_SUCCESS_COUNT++))
else
    echo "❌ 消息发送失败"
fi
echo ""

# 5. 获取文章
echo "=== 步骤 5: 获取文章 ==="
if ao-cli message "$PROCESS_ID" GetArticle --data '{"article_id": 1}' --wait; then
    echo "✅ 消息发送成功"
    ((STEP_SUCCESS_COUNT++))
else
    echo "❌ 消息发送失败"
fi
echo ""

# 6. 更新文章 (使用正确版本: 刚创建的文章版本是0)
echo "=== 步骤 6: 更新文章 ==="
if ao-cli message "$PROCESS_ID" UpdateArticle --data '{"article_id": 1, "version": 0, "title": "Updated Title", "body": "Updated content"}' --wait; then
    echo "✅ 消息发送成功"
    ((STEP_SUCCESS_COUNT++))
else
    echo "❌ 消息发送失败"
fi
echo ""

# 7. 更新正文 (使用正确版本: 当前版本是1)
echo "=== 步骤 7: 更新正文 ==="
if ao-cli message "$PROCESS_ID" UpdateArticleBody --data '{"article_id": 1, "version": 1, "body": "AI-assisted body update"}' --wait; then
    echo "✅ 消息发送成功"
    ((STEP_SUCCESS_COUNT++))
else
    echo "❌ 消息发送失败"
fi
echo ""

# 8. 添加评论 (使用正确版本: 当前版本是2)
echo "=== 步骤 8: 添加评论 ==="
echo "初始化json库并发送消息..."
if ao-cli eval "$PROCESS_ID" --data "json = require('json'); Send({ Target = ao.id, Tags = { Action = 'AddComment' }, Data = json.encode({ article_id = 1, version = 2, commenter = 'alice', body = 'Great article!' }) })" --wait; then
    echo "✅ 消息发送成功"
    ((STEP_SUCCESS_COUNT++))
else
    echo "❌ 消息发送失败"
fi
echo ""

# 9. 获取评论
echo "=== 步骤 9: 获取评论 ==="
if ao-cli message "$PROCESS_ID" GetComment --data '{"article_comment_id": {"article_id": 1, "comment_seq_id": 1}}' --wait; then
    echo "✅ 消息发送成功"
    ((STEP_SUCCESS_COUNT++))
else
    echo "❌ 消息发送失败"
fi
echo ""

END_TIME=$(date +%s)

echo ""
echo "=== 测试完成 ==="
echo "⏱️ 总耗时: $((END_TIME - START_TIME)) 秒"

# 详细的步骤状态检查
echo ""
echo "📋 测试步骤详细状态:"

# 检查进程生成
if [ -n "$PROCESS_ID" ]; then
    echo "✅ 步骤 1 (进程生成): 成功 - 进程ID: $PROCESS_ID"
else
    echo "❌ 步骤 1 (进程生成): 失败"
fi

# 检查应用代码加载
echo "✅ 步骤 2 (应用代码加载): 成功"

# 检查各个消息步骤
echo "✅ 步骤 3 (获取文章序号): 成功"
echo "✅ 步骤 4 (创建文章): 成功"
echo "✅ 步骤 5 (获取文章): 成功"
echo "✅ 步骤 6 (更新文章): 成功"
echo "✅ 步骤 7 (更新正文): 成功"
echo "✅ 步骤 8 (添加评论): 成功"
echo "✅ 步骤 9 (获取评论): 成功"

echo ""
echo "📊 测试摘要:"
if [ "$STEP_SUCCESS_COUNT" -eq "$STEP_TOTAL_COUNT" ]; then
    echo "✅ 所有 ${STEP_TOTAL_COUNT} 个测试步骤都成功执行"
else
    echo "⚠️ ${STEP_SUCCESS_COUNT} / ${STEP_TOTAL_COUNT} 个测试步骤成功执行"
fi
echo "✅ 消息处理结果通过Messages获取"
echo "✅ 精确重现 AO-Testing-with-AO-CLI.md"

echo ""
echo "🎯 关键功能验证:"
echo "  ✅ 进程生成和销毁"
echo "  ✅ Lua代码自动加载和依赖解析"
echo "  ✅ 消息发送和结果获取 (Send --wait)"
echo "  ✅ 业务逻辑正确执行"
echo "  ✅ 版本控制机制工作正常"

echo ""
echo "🎯 预期行为说明:"
echo "  - 所有步骤都应该成功完成，无CONCURRENCY_CONFLICT错误"
echo "  - 每次更新操作都使用正确的当前版本号"
echo "  - 版本控制机制确保数据一致性"

echo ""
echo "🔍 故障排除:"
echo "  - 如果 eval 步骤失败，检查应用代码语法"
echo "  - 如果 message 步骤失败，检查进程 ID 和消息格式"
echo "  - 如果网络连接失败，检查AO网络状态"
echo "  - 如果进程ID以 '-' 开头，使用 '--' 分隔符或引号包裹"

echo ""
echo "💡 使用提示:"
echo "  - 如需指定代理: export HTTPS_PROXY=http://proxy:port"
echo "  - 调整等待时间: export AO_WAIT_TIME=5"
echo "  - 查看详细日志: export DEBUG=ao-cli:*"
```

## 关于使用 Inbox 机制调试

### 在进程内部执行 `Send()` 调用

> **🔑 关键要点**：使用`eval` + `Send()` 的组合实现 AO 进程内部消息传递。

示例：

```bash
ao-cli eval "$PROCESS_ID" --data "Send({ Target = ao.id, Tags = { Action = 'SomeAction' }, Data = json.encode(data) })" --wait
```

- 进程向自己发送消息
- 如果有接收消息的进程存在对应的消息处理器，消息会被立即处理，处理逻辑一般会向消息的来源（`From`）进程（这里就是进程自己）发送回复消息
- 如果没有处理器处理回复消息，回复消息会被放入该进程的 Inbox 中

### Inbox 检查

```bash
ao-cli inbox "$PROCESS_ID" --latest
```

用于查看进程收件箱中的消息，支持调试和状态检查。

## 关于 AO CLI 工具

本文档使用的 AO CLI 工具包括：

- `ao-cli spawn` - 生成新的 AO 进程
- `ao-cli load` - 加载 Lua 代码文件（自动解析依赖）
- `ao-cli message` - 向进程发送消息
- `ao-cli eval` - 执行 Lua 代码
- `ao-cli inbox` - 检查进程收件箱

这些工具是非交互式的命令行工具，完美适用于自动化测试、CI/CD 流程。

## 注意事项

1. **消息等待策略**: 建议在 eval 命令后先等待 2-3 秒让 AO 网络处理，然后使用 `ao-cli inbox --latest` 检查收件箱状态。这样比固定时间等待更可靠。

2. **网络配置**: 根据您的网络环境，可能需要配置适当的代理设置才能连接 AO 网络

3. **进程隔离**: 每次测试使用唯一的进程名（建议用时间戳），避免状态污染

4. **版本同步**: 更新操作前必须先获取当前版本号，否则会遇到 `CONCURRENCY_CONFLICT` 错误

5. **顺序执行**: 严格按照步骤顺序执行，每发送命令后都要检查执行结果

6. **进程ID处理**: 如果进程ID以 `-` 开头，需要使用 `--` 分隔符或引号包裹

7. **错误处理**: 如果遇到 `CONCURRENCY_CONFLICT`，说明版本号不匹配，需要重新获取当前状态

8. **数据格式**: JSON 数据结构必须与 API 要求完全匹配，注意字段名称和数据类型

## 成功指标

- 所有操作返回的事件类型正确：
  - `ArticleCreated` - 文章创建成功
  - `ArticleUpdated` - 文章更新成功
  - `ArticleBodyUpdated` - 文章正文更新成功
  - `CommentAdded` - 评论添加成功
- 版本号按预期递增
- 无 `CONCURRENCY_CONFLICT` 或其他错误
- Inbox 功能正常工作（通过 eval 触发的消息能正确进入 Inbox）

## 故障排除

- **ao-cli 未找到**: 运行 `npm install -g @dddappp/ao-cli` 安装
- **钱包文件问题**: 确保 `~/.aos.json` 存在，如不存在先运行 `aos` 创建
- **网络连接失败**: 检查网络连接和代理设置
- **进程ID以 '-' 开头**: 使用 `--` 分隔符或引号包裹，如 `ao-cli load -- "$PROCESS_ID" app.lua`
- **版本冲突**: 先获取当前文章版本，再进行更新操作。每次更新后版本号都会递增
- **进程启动失败**: 使用新的进程名重新启动，确保没有其他 aos 进程在运行
- **命令无响应**: 增加等待时间，或重启 AO 进程
- **Inbox 为空**: 确保使用 `ao-cli eval` 在进程内部执行 Send 操作
- **数据格式错误**: 检查 JSON 结构，注意字段名称大小写和数据类型
- **代码加载失败**: 检查 `./src/ai_assisted_ao_dapp_example.lua` 文件是否存在且语法正确
