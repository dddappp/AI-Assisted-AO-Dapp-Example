# AI 辅助 AO 去中心化应用开发示例

[English](./README.md) | 中文版


## 前置条件

如果你想跟随我们走一遍演示的流程，请安装下面的工具：

* 安装 [aos](https://cookbook_ao.g8way.io/welcome/getting-started.html)
* 安装 [Docker](https://docs.docker.com/engine/install/).
* 安装 [Cursor IDE](https://www.cursor.com).


## 编码

### 编写 DDDML 模型

已经编写好的模型文件见 `./dddml/blog.yaml`.

对于稍有 OOP（面向对象编程）经验的开发者来说，模型所表达的内容应该不难理解。


也许你会觉得，这样手写 DDDML 模型有点麻烦。我们已经在做 AI 辅助建模的尝试。
也许在不远的将来，你可以使用这样的提示词，得到类似上面那样的 `blog.yaml` 文件：

```text
我想要开发一个 AO 上的 Dapp，请为我推荐一个参考的 DDDML 模型。
这是一个博客应用，主要包含文章及评论实体。
文章包含标题、正文和作者等属性。
我们需要支持文章的创建和修改，但是不能删除。
评论只能针对具体的文章进行，不能发表独立于文章的评论。
评论功能包含一般的 CRUD 方法，即支持创建（新增）、更新、删除。用户在发表评论时可输入供显示用的自己（即评论者）的名字。
```

> **提示**
>
> 关于 DDDML，这里有个介绍文章：["Introducing DDDML: The Key to Low-Code Development for Decentralized Applications"](https://github.com/wubuku/Dapp-LCDP-Demo/blob/main/IntroducingDDDML.md).
>


### 生成代码

在代码库的根目录执行：

```shell
docker run \
-v .:/myapp \
wubuku/dddappp-ao:master \
--dddmlDirectoryPath /myapp/dddml \
--boundedContextName AI-Assisted-AO-Dapp-Example \
--aoLuaProjectDirectoryPath /myapp/src
```

上面的命令行参数实际上还是挺直白的：

* This line `-v .:/myapp \` indicates mounting the local current directory into the `/myapp` directory inside the container.
* `dddmlDirectoryPath` is the directory where the DDDML model files are located. It should be a directory path that can be read in the container.
* Understand the value of the `boundedContextName` parameter as the name of the application you want to develop. When the name has multiple parts, separate them with dots and use the PascalCase naming convention for each part. 
    Bounded-context is a term in Domain-driven design (DDD) that refers to a specific problem domain scope that contains specific business boundaries, constraints, and language. 
    If you cannot understand this concept for the time being, it is not a big deal.
* `aoLuaProjectDirectoryPath` is the directory path where the "on-chain contract" code is placed. It should be a readable and writable directory path in the container.

执行完上面的命令后，你会在 `./src` 目录下看到 dddappp 工具为你生成的代码。


#### 更新 Docker 镜像

由于 dddappp v0.0.1 映像经常更新，如果您之前运行过上述命令，现在遇到了问题，你可能需要手动删除旧的镜像。

```shell
# If you have already run it, you may need to Clean Up Exited Docker Containers first
docker rm $(docker ps -aq --filter "ancestor=wubuku/dddappp-ao:master")
# remove the image
docker image rm wubuku/dddappp-ao:master
# pull the image
docker pull wubuku/dddappp-ao:master
```


### 填充业务逻辑

如果你需要的业务逻辑就是对实体的 CRUD 操作，那么你甚至不用手动编写代码！
你现在就可以跳转到 [测试应用](#测试应用) 一节，开始“测试创建/更新/查看文章”了。

为了测试 AI 辅助编程，我们在模型的文章实体中添加一个方法 `UpdateBody`，它用于更新文章的正文内容。
在 `blog.yaml` 文件的末尾添加如下内容：

```yaml
    methods:
      UpdateBody:
        metadata:
          MessagingCommandName: "UpdateArticleBody"
          # We set this "global" name to prevent naming conflicts between methods of different objects.
        description: "Updates the body of an article"
        parameters:
          Body:
            type: string
        event:
          name: "ArticleBodyUpdated"
```

然后让我们再次执行上面的 `docker run` 命令，再次生成代码。

下面让我们填充以 Lua 代码编写的业务操作逻辑。

你会发现，下面需要填充的后缀为 `_logic.lua` 的文件中，函数的签名部分已经写好了，你只需要填充函数体部分。
你还会发现，在这些 `_logic.lua` 文件中，已经包含了不少注释，这些注释是 dddappp 工具根据 DDDML 模型生成的，
你可能觉得这注释量简直是又长又臭，看着让人有点不厌其烦了；
不过，我们的主要目的是让 AI 可以（当然，你也可以）参考这些注释来完成业务逻辑代码的编写。


#### 实现“更新文章正文”的业务逻辑

使用 Cursor IDE 打开当前代码库目录，然后打开文件 `./src/article_update_body_logic.lua`，
我是这样引导 AI 帮助我生成完成业务逻辑的编码的：
* 使用快捷键 Cmd + A 全选当前文件的代码（我使用的是 macOS 系统，Windows 需用将 Cmd 替换为 Ctrl）。
* 使用快捷键 Cmd + L 打开 CHAT 窗口。
* 输入 `complete the functions`，让 AI 帮我完成函数的编码。

下面是 AI 为我生成的代码：

```lua
local article = require("article")

local article_update_body_logic = {}

function article_update_body_logic.verify(_state, body, cmd, msg, env)
    if type(body) ~= "string" then
        error("Body must be a string")
    end
    if #body == 0 then
        error("Body cannot be empty")
    end
    if #body > 10000 then
        error("Body is too long (max 10000 characters)")
    end
    return article.new_article_body_updated(
        _state,
        body
    )
end

function article_update_body_logic.mutate(state, event, msg, env)
    state.body = event.body
    return state
end

return article_update_body_logic
```

看起来相当不错！你可能一下子都找不到什么明显的缺陷。

让我们点击 CHAT 窗口的 Apply 按钮，将 AI 生成的代码应用到当前文件中；
然后，点击 IDE 窗口的 Accept 按钮，接受对当前文件的修改。


#### 来个更复杂的例子？

也许你要说，上面的例子太简单了，能不能来个复杂点的？

让我们在 `dddml` 目录中新增一个 DDDML 模型文件 `InventoryItem.yaml`。
你可以看看我们已经写好的文件 `./dddml/InventoryItem.yaml` 的内容，看看是不是复杂多了？
* 这个例子中，实体 `InventoryItem` 的 Id 是一个复合值对象 `InventoryItemId`，
* 而 `InventoryItemId` 还“内嵌”了另外一个值对象 `InventoryAttributeSet`。
* 而且实体 `InventoryItem` 的属性 `Entries` 是一个值对象 `InventoryItemEntry` 的列表，它用于记录库存条目的历史变更情况。
* 我们定义了一个方法 `AddInventoryItemEntry`，用于添加库存条目，这个方法会视需要创建或者更新库存单元记录（`shouldCreateOnDemand: true`）……

然后，让我们再次执行 `docker run` 命令，重新生成代码。

> 在[这里](https://gist.github.com/wubuku/ef65acd4e49afaed0dc7481329155e50)保存了 `inventory_item_add_inventory_item_entry_logic.lua` 文件*此刻*的状态——
> 也就是在执行 `docker run` 命令生成它之后，让 AI 执行“完形填空”之前的样子。


打开文件 `./src/inventory_item_add_inventory_item_entry_logic.lua`，
使用在上面介绍过的方法，让 AI 再次 `complete the functions`。

然后，AI 为我完成的代码是这样的：

```lua
local inventory_item = require("inventory_item")

local inventory_item_add_inventory_item_entry_logic = {}

function inventory_item_add_inventory_item_entry_logic.verify(_state, inventory_item_id, movement_quantity, cmd, msg, env)
    if type(movement_quantity) ~= "number" then
        error("movement_quantity must be a number")
    end
    if type(inventory_item_id) ~= "table" or
        type(inventory_item_id.product_id) ~= "number" or
        type(inventory_item_id.location) ~= "string" or
        type(inventory_item_id.inventory_attribute_set) ~= "table" then
        error("Invalid inventory_item_id")
    end
    return inventory_item.new_inventory_item_entry_added(inventory_item_id, _state, movement_quantity)
end

function inventory_item_add_inventory_item_entry_logic.mutate(state, event, msg, env)
    if not state then
        state = inventory_item.new(
            event.inventory_item_id,
            event.movement_quantity,
            {
                {
                    movement_quantity = event.movement_quantity,
                    timestamp = msg.Timestamp or os.time()
                }
            }
        )
    else
        state.quantity = state.quantity + event.movement_quantity
        table.insert(state.entries, {
            movement_quantity = event.movement_quantity,
            timestamp = msg.Timestamp or os.time()
        })
    end
    return state
end

return inventory_item_add_inventory_item_entry_logic
```

我发誓：除了删除注释之外，我没做任何修改！

如果我们粗略检查一下，可能会发现有两个地方，`timestamp = msg.Timestamp or os.time()`，
其中的 `or os.time()` 稍有多余，但问题应该不大。
因为在 AO 中，`msg.Timestamp` 应该会有值，所以应该不会执行到 `os.time()`。
让我们先一字不改，直接进行后面的测试看看。


## 测试应用

启动一个 aos 进程：

```shell
aos ai_ao_test
```

在这个 aos 进程中，装载我们的应用代码（注意将 `{PATH/TO/CURRENT_REPO}` 替换为当前代码库的实际路径）：

```lua
.load {PATH/TO/CURRENT_REPO}/src/ai_assisted_ao_dapp_example.lua
```

装载 json 模块，以便于我们后面处理 JSON 格式的数据：

```lua
json = require("json")
```


### 测试创建/更新/查看文章

我们可以先查看一下当前已经生成的“文章的序号”：

```lua
Send({ Target = ao.id, Tags = { Action = "GetArticleIdSequence" } })
```

你会看到类似这样的回复：

```text
New Message From wkD..._XQ: Data = {"result":[0]}
```

创建一篇新文章：

```lua
Send({ Target = ao.id, Tags = { Action = "CreateArticle" }, Data = json.encode({ title = "Hello", body = "World" }) })
```

在收到回复后，查看最后一条收件箱消息的内容：

```lua
Inbox[#Inbox]
```

如果没有错误，你应该会看到消息的 `Data` 字段包含 `ArticleCreated` 字样的事件信息。

现在，再次查看当前已经生成的“文章的序号”：

```lua
Send({ Target = ao.id, Tags = { Action = "GetArticleIdSequence" } })
```

你应该会看到返回的序号已经变成了 `1`。

可以这样查看序号为 `1` 的文章的内容：

```lua
Send({ Target = ao.id, Tags = { Action = "GetArticle" }, Data = json.encode(1) })

Inbox[#Inbox]
```

你应该可以看到类似这样的输出：

```text
{
   Id = "h5e1RjCckmo9sO03p9OF-EM7VxxhOecITB4kMNm1sKo",
   Signature = "...",
   forward = function: 0x4156ae0,
   Timestamp = 1727671644410,
   Epoch = 0,
   Anchor = "00000000000000000000000000000008",
   Data = "{"result":{"article_id":1,"author":"fcoN_xJeisVsPXA-trzVAuIiqO3ydLQxM-L4XbrQKzY","body":"World","version":0,"title":"Hello"}}",
```

更新序号为 `1` 的文章（注意 `version` 的值应该与上面看到的当前文章的版本号一致）：

```lua
Send({ Target = ao.id, Tags = { Action = "UpdateArticle" }, Data = json.encode({ article_id = 1, version = 0, title = "Hello", body = "New World!" }) })
```

再次查看序号为 `1` 的文章的内容：

```lua
Send({ Target = ao.id, Tags = { Action = "GetArticle" }, Data = json.encode(1) })

Inbox[#Inbox]
```


### 测试“更新文章正文”

如果你在上次 `.loal` 文件 `ai_assisted_ao_dapp_example.lua` 之后修改了代码（比如更新了 `article_update_body_logic.lua` 文件），那么你需要重新装载应用：

```lua
.loal {PATH/TO/CURRENT_REPO}/src/ai_assisted_ao_dapp_example.lua
```

让我们使用 `Article.UpdateBody` 方法更新序号为 `1` 的文章的正文
（注意将 `version` 的值设置为正确的值，如果你不确定它是什么，
可以再次向 aos 进程发送 `GetArticle` 消息，然后 `Inbox[#Inbox]` 查看收件箱的最后一条消息，
查看文章的当前版本号）：

```lua
Send({ Target = ao.id, Tags = { Action = "UpdateArticleBody" }, Data = json.encode({ article_id = 1, version = 1, body = "New world of AI!" }) })
```

如果没有什么意外，你会看到类似这样的回复：

```text
New Message From wkD..._XQ: Data = {"result":{"body":"N
```

再次查看序号为 `1` 的文章的内容：

```lua
Send({ Target = ao.id, Tags = { Action = "GetArticle" }, Data = json.encode(1) })

Inbox[#Inbox]
```

你应该可以看到文章的正文已经更新为 `New world of AI!`：

```text
 Data = "{"result":{"article_id":1,"author":"fcoN_xJeisVsPXA-trzVAuIiqO3ydLQxM-L4XbrQKzY","body":"New world of AI!","version":2,"title":"Hello"}}",
```


### 测试添加/修改/删除评论


给序号为 `1` 的文章添加评论（注意将文章的 `version` 设置为正确的值）：

```lua
Send({ Target = ao.id, Tags = { Action = "AddComment" }, Data = json.encode({ article_id = 1, version = 2, commenter = "alice", body = "This looks great." }) })
```

查看评论信息，如果之前没有给文章添加过评论，那么你新添加的评论的 `comment_seq_id` 应该是 `1`：

```lua
Send({ Target = ao.id, Tags = { Action = "GetComment" }, Data = json.encode({ article_id = 1, comment_seq_id = 1 }) })

Inbox[#Inbox]
```

你应该可以看到类似这样的输出：

```text
 Data = "{"result":{"commenter":"alice","body":"This looks great.","comment_seq_id":1}}",
```

更新你刚发表的评论：

```lua
Send({ Target = ao.id, Tags = { Action = "UpdateComment" }, Data = json.encode({ article_id = 1, version = 3, comment_seq_id = 1, commenter = "alice", body = "It's better than I thought!" }) })
```

再次查看评论信息：

```lua
Send({ Target = ao.id, Tags = { Action = "GetComment" }, Data = json.encode({ article_id = 1, comment_seq_id = 1 }) })

Inbox[#Inbox]
```

你应该可以看到评论的内容已经被更新。

移除你刚发表的评论：

```lua
Send({ Target = ao.id, Tags = { Action = "RemoveComment" }, Data = json.encode({ article_id = 1, version = 4, comment_seq_id = 1 }) })
```

再次查看评论信息：

```lua
Send({ Target = ao.id, Tags = { Action = "GetComment" }, Data = json.encode({ article_id = 1, comment_seq_id = 1 }) })

Inbox[#Inbox]
```

你应该会看到类似这样的输出：

```text
New Message From wkD..._XQ: Data = {"error":"ID_NOT_EXI
```

你可以再次查看收件箱的最后条消息，完整的错误代码应该是 `ID_NOT_EXISTS`，这证明评论确实已经被移除。



### 测试库存单元（Inventory Item）操作

如果你在上次 `.loal` 文件 `ai_assisted_ao_dapp_example.lua` 之后修改了代码，那么你需要重新装载应用。

我们通过调用“添加库存单元条目”方法来添加库存单元：

```lua
Send({ Target = ao.id, Tags = { Action = "AddInventoryItemEntry" }, Data = json.encode({ inventory_item_id = { product_id = 1, location = "x", inventory_attribute_set = {} }, movement_quantity = 100}) })
```

等待收件箱收到 `InventoryItemEntryAdded` 事件消息后，可以这样查看库存单元数据：

```lua
Send({ Target = ao.id, Tags = { Action = "GetInventoryItem" }, Data = json.encode({ product_id = 1, location = "x", inventory_attribute_set = {} }) })

Inbox[#Inbox]
```

你应该可以看到类似这样的输出：

```text
   Data = "{"result":{"entries":[{"movement_quantity":100,"timestamp":1727689714409}],"version":0,"inventory_item_id":{"location":"x","product_id":1,"inventory_attribute_set":[]},"quantity":100}}",
```

让我们再次通过“添加库存单元条目”来添加库存单元的数量：

```lua
Send({ Target = ao.id, Tags = { Action = "AddInventoryItemEntry" }, Data = json.encode({ inventory_item_id = { product_id = 1, location = "x" ,inventory_attribute_set = {} }, movement_quantity = 130, version = 0}) })
```

等待收件箱收到 `InventoryItemEntryAdded` 事件消息，然后再次查看库存单元数据：

```lua
Send({ Target = ao.id, Tags = { Action = "GetInventoryItem" }, Data = json.encode({ product_id = 1, location = "x", inventory_attribute_set = {} }) })

Inbox[#Inbox]
```

现在你应该看到类似这样的输出：

```text
   Data = "{"result":{"entries":[{"movement_quantity":100,"timestamp":1727689714409},{"movement_quantity":130,"timestamp":1727689995779}],"inventory_item_id":{"location":"x","product_id":1,"inventory_attribute_set":[]},"version":1,"quantity":230}}",
```

你可以看到，库存单元的数量已经更新为 230（`"quantity":230`）。


## 延伸阅读

### 低代码开发 AO Dapp 的更复杂的示例

我们的低代码工具现在可以为 AO Dapp 开发所做的事情，比上面演示的例子还要多一些。
这里有更复杂的示例：https://github.com/dddappp/A-AO-Demo/blob/main/README_CN.md


### Sui 博客示例

代码库：https://github.com/dddappp/sui-blog-example

只需要写 30 行左右的代码（全部是领域模型的描述）——除此以外不需要开发者写一行其他代码——就可以一键生成一个博客；
类似 [RoR 入门指南](https://guides.rubyonrails.org/getting_started.html) 的开发体验，

特别是，一行代码都不用写，100% 自动生成的链下查询服务（有时候我们称之为 indexer）即具备很多开箱即用的功能。


### Aptos 博客示例

上面的博客示例的 [Aptos 版本](https://github.com/dddappp/aptos-blog-example)。

### Sui 众筹 Dapp

一个以教学演示为目的“众筹” Dapp：

https://github.com/dddappp/sui-crowdfunding-example


#### 使用 dddappp 开发 Sui 全链游戏

这个一个生产级的实际案例：https://github.com/wubuku/infinite-sea


#### 用于开发 Aptos 全链游戏的示例

原版的 [constantinople](https://github.com/0xobelisk/constantinople) 是一个基于全链游戏引擎 [obelisk](https://obelisk.build) 开发的运行在 Sui 上的游戏。（注：obelisk 不是我们的项目。）

我们这里尝试了使用 dddappp 低代码开发方式，实现这个游戏的 Aptos Move 版本：https://github.com/wubuku/aptos-constantinople/blob/main/README_CN.md

开发者可以按照 README 的介绍，复现整个游戏的合约和 indexer 的开发和测试过程。模型文件写一下，生成代码，在三个文件里面填了下业务逻辑，开发就完成了。

有个地方可能值得一提。Aptos 对发布的 Move 合约包的大小有限制（不能超过60k）。这个问题在 Aptos 上开发稍微大点的应用都会碰到。我们现在可以在模型文件里面声明一些模块信息，然后就可以自动拆分（生成）多个 Move 合约项目。（注：这里说的模块是指 DDD 术语中的模块，不是 Move 语言的那个模块概念。）


