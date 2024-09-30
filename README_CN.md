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
你可能觉得这注释量简直是有点“不厌其烦”了；
我们的目的是让 AI 可以（当然，你也可以）参考这些注释来完成业务逻辑代码的编写。


#### 修改 `article_update_body_logic`

使用 Cursor IDE 开发当前代码库的目录，然后打开文件 `./src/article_update_body_logic.lua`，我是这样让 AI 帮助我生成代码的：
* 使用快捷键 Cmd + A 全选当前文件的代码
* 使用快捷键 Cmd + L 打开 CHAT 窗口
* 输入 `complete functions`，让 AI 帮我完成函数的编码


这是 AI 为我生成的代码：

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


## 测试应用

启动另一个 aos 进程：

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

再次查看当前已经生成的“文章的序号”：

```lua
Send({ Target = ao.id, Tags = { Action = "GetArticleIdSequence" } })
```

查看序号为 `1` 的文章的内容（在输出消息的 `Data` 属性中）：

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

如果你在上次 `.loal` 文件 `ai_assisted_ao_dapp_example.lua` 之后修改了代码（比如生成和更新了 `article_update_body_logic.lua` 文件），那么你需要重新装载应用：

```lua
.loal {PATH/TO/CURRENT_REPO}/src/ai_assisted_ao_dapp_example.lua
```

让我们使用 `Article.UpdateBody` 方法更新序号为 `1` 的文章的正文（注意将 `version` 的值设置为正确的值，如果你不确定，可以向进程发送 `GetArticle` 命令来再次查看文章的当前版本号）：

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


添加评论（注意将 `version` 的值设置为正确的值）：

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

证明评论已经被移除。


【TBD】

