# AO 库存管理应用自动化测试指南

本文档指导开发者/AI编程助手如何使用 MCP 工具自动化测试 AO Dapp 示例项目中的库存管理功能。

## 前置条件

### 1. 已安装的工具
- [aos](https://cookbook_ao.g8way.io/welcome/getting-started.html) - AO 操作系统客户端
- [Docker](https://docs.docker.com/engine/install/) - 用于代码生成
- [Cursor IDE](https://www.cursor.com) - 支持 MCP 工具的开发环境

### 2. MCP 工具配置
确保您的开发环境已正确配置以下 MCP 工具：
- `mcp_iterm-mcp_write_to_terminal` - 向终端写入命令
- `mcp_iterm-mcp_read_terminal_output` - 读取终端输出

### 3. 项目结构确认
确保项目目录包含以下关键文件：
- `src/ai_assisted_ao_dapp_example.lua` - 主应用文件
- 其他生成的业务逻辑文件（.lua 文件）

注意：测试时不需要存在 DDDML 模型文件，因为测试的是已经生成的代码。

## 环境准备

### 1. 网络配置（根据需要）
如果您的网络环境需要代理才能访问 AO 网络，请根据您的实际情况配置相应的环境变量：

```bash
# 根据您的网络环境配置以下变量（如果需要）
export HTTPS_PROXY=http://your-proxy-host:port
export HTTP_PROXY=http://your-proxy-host:port
export ALL_PROXY=socks5://your-proxy-host:port

# 禁用 AOS 命令的彩色输出（可选，提高兼容性）
export AOS_NO_COLOR=1
```

### 2. 进入项目目录
```bash
cd /path/to/your/project
```

## 测试流程

### 步骤 1: 启动全新 AO 进程
```bash
# 进入项目目录
mcp_iterm-mcp_write_to_terminal command="cd /path/to/your/project"

# 配置网络（如果需要）
mcp_iterm-mcp_write_to_terminal command="export AOS_NO_COLOR=1"

# 启动 AO 进程（使用时间戳确保进程名唯一）
# 注意：aos 会显示交互式菜单，需要自动选择第一个选项（aos）
mcp_iterm-mcp_write_to_terminal command="aos inventory-test-$(date +%s)"
```

⚠️ **重要**: aos 启动时会显示交互式菜单：
```
? Please select › - Use arrow-keys. Return to submit.
❯   aos
    hyper-aos (experimental - DO NOT USE FOR PRODUCTION)
```

执行上面的命令后，立即执行下一步来自动选择默认选项。

### 步骤 2: 自动选择 aos 选项并等待启动
```bash
# 发送回车键选择默认的 "aos" 选项
mcp_iterm-mcp_write_to_terminal command=""

# 等待 aos REPL 完全启动（显示进程信息）
mcp_iterm-mcp_read_terminal_output linesOfOutput=30
```

### 步骤 3: 加载应用代码
```bash
# 等待 REPL 提示符出现后再加载代码
mcp_iterm-mcp_read_terminal_output linesOfOutput=10
mcp_iterm-mcp_write_to_terminal command=".load ./src/ai_assisted_ao_dapp_example.lua"

# 等待代码加载完成
mcp_iterm-mcp_read_terminal_output linesOfOutput=25
```

### 步骤 4: 初始化环境
```bash
# 加载 JSON 库用于数据序列化
mcp_iterm-mcp_read_terminal_output linesOfOutput=10
mcp_iterm-mcp_write_to_terminal command="json = require(\"json\")"
mcp_iterm-mcp_read_terminal_output linesOfOutput=5
```

### 步骤 5: 执行库存功能测试

#### 5.1 添加第一个库存条目
```bash
# 添加库存条目（创建新的库存项目）
mcp_iterm-mcp_write_to_terminal command="Send({ Target = ao.id, Tags = { Action = \"AddInventoryItemEntry\" }, Data = json.encode({ inventory_item_id = { product_id = 1, location = \"warehouse_A\", inventory_attribute_set = {} }, movement_quantity = 100 }) })"
mcp_iterm-mcp_read_terminal_output linesOfOutput=10

# 查看库存添加结果（应该包含 InventoryItemEntryAdded 事件）
mcp_iterm-mcp_write_to_terminal command="print(Inbox[#Inbox].Data)"
mcp_iterm-mcp_read_terminal_output linesOfOutput=5
```

#### 5.2 获取库存项目详情
```bash
# 获取库存项目详情（验证第一次添加是否成功）
mcp_iterm-mcp_write_to_terminal command="Send({ Target = ao.id, Tags = { Action = \"GetInventoryItem\" }, Data = json.encode({ product_id = 1, location = \"warehouse_A\", inventory_attribute_set = {} }) })"
mcp_iterm-mcp_read_terminal_output linesOfOutput=10

# 查看库存数据（应该显示 quantity: 100, version: 0）
mcp_iterm-mcp_write_to_terminal command="print(Inbox[#Inbox].Data)"
mcp_iterm-mcp_read_terminal_output linesOfOutput=10
```

#### 5.3 测试库存累加功能
```bash
# 再次添加库存条目（测试累加功能，使用 version: 0）
mcp_iterm-mcp_write_to_terminal command="Send({ Target = ao.id, Tags = { Action = \"AddInventoryItemEntry\" }, Data = json.encode({ inventory_item_id = { product_id = 1, location = \"warehouse_A\", inventory_attribute_set = {} }, movement_quantity = 50, version = 0 }) })"
mcp_iterm-mcp_read_terminal_output linesOfOutput=10

# 查看累加结果（应该包含 InventoryItemEntryAdded 事件）
mcp_iterm-mcp_write_to_terminal command="print(Inbox[#Inbox].Data)"
mcp_iterm-mcp_read_terminal_output linesOfOutput=5

# 再次获取库存项目详情（验证累加是否成功）
mcp_iterm-mcp_write_to_terminal command="Send({ Target = ao.id, Tags = { Action = \"GetInventoryItem\" }, Data = json.encode({ product_id = 1, location = \"warehouse_A\", inventory_attribute_set = {} }) })"
mcp_iterm-mcp_read_terminal_output linesOfOutput=10

# 查看最终库存数据（应该显示 quantity: 150, version: 1，两条历史记录）
mcp_iterm-mcp_write_to_terminal command="print(Inbox[#Inbox].Data)"
mcp_iterm-mcp_read_terminal_output linesOfOutput=10
```

#### 5.4 测试库存减少（负数操作）
```bash
# 添加负数库存条目（模拟出库操作）
mcp_iterm-mcp_write_to_terminal command="Send({ Target = ao.id, Tags = { Action = \"AddInventoryItemEntry\" }, Data = json.encode({ inventory_item_id = { product_id = 1, location = \"warehouse_A\", inventory_attribute_set = {} }, movement_quantity = -30, version = 1 }) })"
mcp_iterm-mcp_read_terminal_output linesOfOutput=10

# 查看减少结果
mcp_iterm-mcp_write_to_terminal command="print(Inbox[#Inbox].Data)"
mcp_iterm-mcp_read_terminal_output linesOfOutput=5

# 获取最终库存状态（应该显示 quantity: 120, version: 2，三条历史记录）
mcp_iterm-mcp_write_to_terminal command="Send({ Target = ao.id, Tags = { Action = \"GetInventoryItem\" }, Data = json.encode({ product_id = 1, location = \"warehouse_A\", inventory_attribute_set = {} }) })"
mcp_iterm-mcp_read_terminal_output linesOfOutput=10
mcp_iterm-mcp_write_to_terminal command="print(Inbox[#Inbox].Data)"
mcp_iterm-mcp_read_terminal_output linesOfOutput=10
```

#### 5.5 测试不同产品的库存
```bash
# 为不同产品创建库存
mcp_iterm-mcp_write_to_terminal command="Send({ Target = ao.id, Tags = { Action = \"AddInventoryItemEntry\" }, Data = json.encode({ inventory_item_id = { product_id = 2, location = \"warehouse_B\", inventory_attribute_set = {} }, movement_quantity = 200 }) })"
mcp_iterm-mcp_read_terminal_output linesOfOutput=10
mcp_iterm-mcp_write_to_terminal command="print(Inbox[#Inbox].Data)"
mcp_iterm-mcp_read_terminal_output linesOfOutput=5

# 验证不同产品的库存独立性
mcp_iterm-mcp_write_to_terminal command="Send({ Target = ao.id, Tags = { Action = \"GetInventoryItem\" }, Data = json.encode({ product_id = 2, location = \"warehouse_B\", inventory_attribute_set = {} }) })"
mcp_iterm-mcp_read_terminal_output linesOfOutput=10
mcp_iterm-mcp_write_to_terminal command="print(Inbox[#Inbox].Data)"
mcp_iterm-mcp_read_terminal_output linesOfOutput=10
```

### 步骤 6: 退出测试
```bash
# 退出 aos REPL
mcp_iterm-mcp_write_to_terminal command=".exit"
```

## 自动化测试脚本示例

```bash
#!/bin/bash
set -e

echo "=== AO 库存管理应用自动化测试脚本 ==="

# 以下是使用 MCP 工具执行自动化测试的命令序列
# 注意：这些命令需要通过支持 MCP 的开发环境执行

# 1. 切换到项目目录并设置环境
echo "1. 准备环境..."
# mcp_iterm-mcp_write_to_terminal command="cd /path/to/your/project"
# mcp_iterm-mcp_write_to_terminal command="export AOS_NO_COLOR=1"

# 2. 启动 AO 进程
echo "2. 启动 AO 进程..."
# mcp_iterm-mcp_write_to_terminal command="aos inventory-test-$(date +%s)"

# 3. 自动选择 aos 选项
echo "3. 自动选择 aos 选项..."
# mcp_iterm-mcp_write_to_terminal command=""
# mcp_iterm-mcp_read_terminal_output linesOfOutput=30

# 4. 加载应用代码
echo "4. 加载应用代码..."
# mcp_iterm-mcp_read_terminal_output linesOfOutput=10
# mcp_iterm-mcp_write_to_terminal command=".load ./src/ai_assisted_ao_dapp_example.lua"
# mcp_iterm-mcp_read_terminal_output linesOfOutput=25

# 5. 初始化 JSON 库
echo "5. 初始化环境..."
# mcp_iterm-mcp_read_terminal_output linesOfOutput=10
# mcp_iterm-mcp_write_to_terminal command="json = require(\"json\")"
# mcp_iterm-mcp_read_terminal_output linesOfOutput=5

# 6. 执行库存功能测试
echo "6. 执行库存功能测试..."

# 添加库存条目
echo "  - 添加库存条目"
# mcp_iterm-mcp_write_to_terminal command="Send({ Target = ao.id, Tags = { Action = \"AddInventoryItemEntry\" }, Data = json.encode({ inventory_item_id = { product_id = 1, location = \"warehouse_A\", inventory_attribute_set = {} }, movement_quantity = 100 }) })"
# mcp_iterm-mcp_read_terminal_output linesOfOutput=10
# mcp_iterm-mcp_write_to_terminal command="print(Inbox[#Inbox].Data)"
# mcp_iterm-mcp_read_terminal_output linesOfOutput=5

# 更多测试步骤请参考文档详细说明
echo "  - 更多测试步骤请参考文档详细说明"

# 7. 退出测试
echo "7. 退出测试..."
# mcp_iterm-mcp_write_to_terminal command=".exit"

echo "=== 测试完成 ==="
```

## 关于 MCP 工具

本文档中使用的 MCP（Machine Control Protocol）工具是一套用于自动化终端操作的工具集。主要包括：

- `mcp_iterm-mcp_write_to_terminal`: 向终端写入命令
- `mcp_iterm-mcp_read_terminal_output`: 读取终端输出
- `mcp_iterm-mcp_send_control_character`: 发送控制字符

这些工具可以在支持 MCP 的各种开发环境中使用，不限于特定的 IDE。

## 注意事项

1. **网络配置**: 根据您的网络环境，可能需要配置适当的代理设置才能连接 AO 网络
2. **MCP 工具**: 确保您的开发环境支持并正确配置了 MCP 工具
3. **进程隔离**: 每次测试使用唯一的进程名（建议用时间戳），避免状态污染
4. **版本同步**: 更新操作前必须先获取当前版本号，否则会遇到 `CONCURRENCY_CONFLICT` 错误
5. **顺序执行**: 严格按照步骤顺序执行，每发送命令后都要读取输出确认执行结果
6. **读取输出**: 每次发送命令后都要调用 `mcp_iterm-mcp_read_terminal_output` 检查执行结果
7. **错误处理**: 如果遇到 `CONCURRENCY_CONFLICT`，说明版本号不匹配，需要重新获取当前状态
8. **等待时机**: aos 启动和代码加载需要时间，适当增加 `linesOfOutput` 值确保命令完全执行
9. **数据格式**: JSON 数据结构必须与 API 要求完全匹配，注意字段名称和数据类型

## 成功指标

- 所有操作返回的事件类型正确：
  - `InventoryItemEntryAdded` - 库存条目添加成功
- 库存数量按预期累加/减少
- 版本号按预期递增
- 不同产品/位置的库存相互独立
- 历史记录正确维护
- 无 `CONCURRENCY_CONFLICT` 或其他错误

## 相关文档

- 如需测试博客功能，请参考 [`AO-Testing-with-iTerm-MCP-Server.md`](AO-Testing-with-iTerm-MCP-Server.md)

## 故障排除

- **网络连接失败**: 检查网络连接和代理设置（如果使用），尝试 `export AOS_NO_COLOR=1` 简化输出
- **版本冲突**: 先获取当前库存版本，再进行更新操作。每次更新后版本号都会递增
- **进程启动失败**: 使用新的进程名重新启动，确保没有其他 aos 进程在运行
- **命令无响应**: 增加 `linesOfOutput` 值，检查网络连接，或重启 aos 进程
- **JSON 库未加载**: 确保在发送 JSON 相关命令前先执行 `json = require("json")`
- **MCP 工具问题**: 确认开发环境中 MCP 工具的配置是否正确，检查 iTerm 是否正在运行
- **代码加载失败**: 检查 `./src/ai_assisted_ao_dapp_example.lua` 文件是否存在且语法正确
- **数据格式错误**: 检查 JSON 结构，注意字段名称大小写和数据类型
- **aos 选择菜单**: 如果卡在选择菜单，发送空命令 `""` 选择默认选项
- **Inbox 为空**: 确保命令发送成功，等待足够的时间让 AO 网络处理请求
- **库存计算错误**: 检查 movement_quantity 的正负值，确认累加逻辑是否正确
