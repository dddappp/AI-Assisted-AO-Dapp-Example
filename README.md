# AI-Assisted AO Decentralized Application Development Example

English | [中文版](./README_CN.md)

What will our low-code platform turn the Dapp development process into?

Dapp developers only need to do two things:

* Modeling.
    * Use DSL to create model files, either manually or with visual tools. AI can also assist modeling in the future.
* Implement specific business logic code.
    * If CRUD operations are sufficient for the application's business logic, no additional code is needed.
    * Otherwise, fill in the code using the language required by the "smart contract platform" (for AO, it's Lua code; for Sui and Aptos, it's Move; for EVM, the mainstream choice is Solidity). Ideally, a platform-independent expression language could be used in the future.

We believe that AI can provide tremendous help in both of these areas.
This article primarily presents some of our attempts in the latter area. To be honest, AI's performance has been quite impressive.
Regarding the former area, while it's not the focus of this article, we already have some very specific ideas that we believe can be implemented, and we're conducting some experimental explorations.


## Prerequisites

If you want to follow us through the process of the demo, install the tools below:

* Install [aos](https://cookbook_ao.g8way.io/welcome/getting-started.html)
* Install [Docker](https://docs.docker.com/engine/install/).
* Install [Cursor IDE](https://www.cursor.com).



## Programming

### Write DDDML Model

The model file that has been written is available at [`./dddml/blog.yaml`](./dddml/blog.yaml).

For developers with some experience in OOP (Object-Oriented Programming), what the model expresses should not be difficult to understand.

You might think that manually writing DDDML models is a bit cumbersome. We are already experimenting with AI-assisted modeling.
Perhaps in the near future, you can use prompts like this to get a `blog.yaml` file similar to the one above:

```text
I want to develop a Dapp on AO, please recommend a reference DDDML model for me.
This is a blog application, mainly containing article and comment entities.
Articles include attributes such as title, body, and author.
We need to support the creation and modification of articles, but not deletion.
Comments can only be made on specific articles, and cannot be posted independently of articles.
The comment functionality includes general CRUD methods, i.e., support for creating (adding), updating, and deleting.
Users can input their own name (i.e., the commenter's name) for display when posting a comment.
```

> **Tip**
>
> Here's an introductory article about DDDML: ["Introducing DDDML: The Key to Low-Code Development for Decentralized Applications"](https://github.com/wubuku/Dapp-LCDP-Demo/blob/main/IntroducingDDDML.md).
>


### Generate Code

Execute the following in the root directory of the code repository:

```shell
docker run \
-v .:/myapp \
wubuku/dddappp-ao:master \
--dddmlDirectoryPath /myapp/dddml \
--boundedContextName AI-Assisted-AO-Dapp-Example \
--aoLuaProjectDirectoryPath /myapp/src
```

The command line parameters above are actually quite straightforward:

* This line `-v .:/myapp \` indicates mounting the local current directory into the `/myapp` directory inside the container.
* `dddmlDirectoryPath` is the directory where the DDDML model files are located. It should be a directory path that can be read in the container.
* Understand the value of the `boundedContextName` parameter as the name of the application you want to develop. When the name has multiple parts, separate them with dots and use the PascalCase naming convention for each part. 
    Bounded-context is a term in Domain-driven design (DDD) that refers to a specific problem domain scope that contains specific business boundaries, constraints, and language. 
    If you cannot understand this concept for the time being, it is not a big deal.
* `aoLuaProjectDirectoryPath` is the directory path where the "on-chain contract" code is placed. It should be a readable and writable directory path in the container.

After executing the above command, you will see the code generated by the dddappp tool in the [`./src`](./src) directory.


#### Update Docker Image

Since the dddappp-ao:master image is frequently updated, if you have run the above command before and are now encountering issues, you may need to manually delete the old image to ensure you are using the latest version of the image.

```shell
# If you have already run it, you may need to Clean Up Exited Docker Containers first
docker rm $(docker ps -aq --filter "ancestor=wubuku/dddappp-ao:master")
# remove the image
docker image rm wubuku/dddappp-ao:master
# pull the image
docker pull wubuku/dddappp-ao:master
```


### Fill in Business Logic

If the business logic you need is just CRUD operations on entities, you don't even need to write code manually!
You can now jump to the [Test Application](#test-application) section and start "testing create/update/view articles".

To test AI-assisted programming, we add a method `UpdateBody` to the article entity in the model, which is used to update the body content of the article.
Add the following content to the end of the [`blog.yaml`](./dddml/blog.yaml) file:


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

Then let's execute the `docker run` command above again to regenerate the code.

Now let's fill in the business operation logic written in Lua code.

You'll find that in the files with the suffix `_logic.lua` that need to be filled in below, the function signature part has already been written, you just need to fill in the function body part.
You'll also find that these `_logic.lua` files already contain quite a few comments, which are generated by the dddappp tool based on the DDDML model.
You might think these comments are long-winded and a bit annoying to look at;
However, our main purpose is to let AI (and of course, you can too) refer to these comments to complete the writing of business logic code.


#### Implement the Business Logic for "Updating Article Body"

Open the current code repository directory using Cursor IDE, then open the file [`./src/article_update_body_logic.lua`](./src/article_update_body_logic.lua).
This is how I guided AI to help me generate and complete the business logic coding:
* Use the shortcut Cmd + A to select all the code in the current file (I'm using macOS, Windows users need to replace Cmd with Ctrl).
* Use the shortcut Cmd + L to open the CHAT window.
* Enter `complete the functions` to let AI help me complete the function coding.

Here's the code AI generated for me:

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
It looks pretty good! You might not even be able to find any obvious flaws at first glance.

Let's click the Apply button in the CHAT window to apply the AI-generated code to the current file;
Then, click the Accept button in the IDE window to accept the changes to the current file.


#### Want a more complex example?

Maybe you're saying that the above example is too simple, can we have something more complex?

Let's add a new DDDML model file `InventoryItem.yaml` in the `dddml` directory.
You can take a look at the content of the file [`./dddml/InventoryItem.yaml`](./dddml/InventoryItem.yaml) that we've already written, see if it's more complex?
* In this example, the Id of the `InventoryItem` entity is a composite value object `InventoryItemId`,
* And `InventoryItemId` also "embeds" another value object `InventoryAttributeSet`.
* Moreover, the `Entries` property of the `InventoryItem` entity is a list of value objects `InventoryItemEntry`, which is used to record the historical changes of inventory entries.
* We defined a method `AddInventoryItemEntry` to add inventory entries, this method will create or update inventory unit records as needed (`shouldCreateOnDemand: true`)...

Then, let's execute the `docker run` command again to regenerate the code.

> [Here](https://gist.github.com/wubuku/ef65acd4e49afaed0dc7481329155e50) is the state of the `inventory_item_add_inventory_item_entry_logic.lua` file *at this moment* —
> That is, after executing the `docker run` command to generate it, before letting AI perform the "complete the functions" operation.


Open the file [`./src/inventory_item_add_inventory_item_entry_logic.lua`](./src/inventory_item_add_inventory_item_entry_logic.lua),
Using the method introduced above, let AI `complete the functions` again.

Then, the code AI completed for me is like this:

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

I swear: Except for deleting comments, I didn't make any modifications! `:-)`

If we roughly check, we might find that in two places, `timestamp = msg.Timestamp or os.time()`,
the `or os.time()` part is slightly redundant, but it shouldn't be a big problem.
Because in AO, `msg.Timestamp` should have a value, so it shouldn't execute `os.time()`.
Let's leave it unchanged for now and proceed with the testing later.


## Test Application


Start an aos process:

```shell
aos ai_ao_test
```

In this aos process, load our application code (note to replace {`PATH/TO/CURRENT_REPO`} with the actual path of the current code repository):

```lua
.load {PATH/TO/CURRENT_REPO}/src/ai_assisted_ao_dapp_example.lua
```

> Actually, you can start another aos process, such as `aos process_alice`, and then execute the following tests in this `process_alice` process.
> However, note that when executing tests in the `process_alice` process, you need to replace the value of the `Target` parameter in the `Send` function with the ID of the `ai_ao_test` process.

Load the json module to help us process JSON format data later:

```lua
json = require("json")
```


### Test Creating/Updating/Viewing Articles

We can first check the current "article sequence Id" that has been generated:

```lua
Send({ Target = ao.id, Tags = { Action = "GetArticleIdSequence" } })
```

You will see a reply similar to this:

```text
New Message From wkD..._XQ: Data = {"result":[0]}
```

Create a new article:

```lua
Send({ Target = ao.id, Tags = { Action = "CreateArticle" }, Data = json.encode({ title = "Hello", body = "World" }) })
```

After receiving the reply, view the content of the last inbox message:

```lua
Inbox[#Inbox]
```


If there are no errors, you should see event information containing the word `ArticleCreated` in the `Data` field of the message.

Now, check the "article sequence Id" that has been generated again:

```lua
Send({ Target = ao.id, Tags = { Action = "GetArticleIdSequence" } })
```

You should see that the returned sequence number has become `1`.
You can view the content of the article with sequence Id `1` like this:

```lua
Send({ Target = ao.id, Tags = { Action = "GetArticle" }, Data = json.encode(1) })

Inbox[#Inbox]
```

You should see output similar to this:

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

Update the article with sequence number `1` (note that the value of `version` should be consistent with the current version number of the article you saw above):

```lua
Send({ Target = ao.id, Tags = { Action = "UpdateArticle" }, Data = json.encode({ article_id = 1, version = 0, title = "Hello", body = "New World!" }) })
```

View the content of the article with sequence Id `1` again:

```lua
Send({ Target = ao.id, Tags = { Action = "GetArticle" }, Data = json.encode(1) })

Inbox[#Inbox]
```


### Test "Updating Article Body"


If you have modified the code after the last `.load` of the `ai_assisted_ao_dapp_example.lua` file (for example, updated the `article_update_body_logic.lua` file), then you need to reload the application:

```lua
.loal {PATH/TO/CURRENT_REPO}/src/ai_assisted_ao_dapp_example.lua
```

Let's use the `Article.UpdateBody` method to update the body of the article with sequence number `1`
(note to set the value of `version` correctly, if you're not sure what it is,
you can send the `GetArticle` message to the aos process again, then use `Inbox[#Inbox]` to view the last message in the inbox,
check the current version number of the article):

```lua
Send({ Target = ao.id, Tags = { Action = "UpdateArticleBody" }, Data = json.encode({ article_id = 1, version = 1, body = "New world of AI!" }) })
```

If nothing unexpected happens, you should see a reply similar to this:

```text
New Message From wkD..._XQ: Data = {"result":{"body":"N
```

View the content of the article with sequence Id `1` again:

```lua
Send({ Target = ao.id, Tags = { Action = "GetArticle" }, Data = json.encode(1) })

Inbox[#Inbox]
```

You should be able to see that the body of the article has been updated to `New world of AI!`:

```text
 Data = "{"result":{"article_id":1,"author":"fcoN_xJeisVsPXA-trzVAuIiqO3ydLQxM-L4XbrQKzY","body":"New world of AI!","version":2,"title":"Hello"}}",
```


### Test Adding/Modifying/Deleting Comments

Add a comment to the article with sequence Id `1` (note to set the `version` of the article to the correct value):

```lua
Send({ Target = ao.id, Tags = { Action = "AddComment" }, Data = json.encode({ article_id = 1, version = 2, commenter = "alice", body = "This looks great." }) })
```

View the comment information. If you haven't added any comments to the article before, the `comment_seq_id` of your newly added comment should be `1`:

```lua
Send({ Target = ao.id, Tags = { Action = "GetComment" }, Data = json.encode({ article_id = 1, comment_seq_id = 1 }) })

Inbox[#Inbox]
```

You should see output similar to this:

```text
 Data = "{"result":{"commenter":"alice","body":"This looks great.","comment_seq_id":1}}",
```

Update the comment you just posted:

```lua
Send({ Target = ao.id, Tags = { Action = "UpdateComment" }, Data = json.encode({ article_id = 1, version = 3, comment_seq_id = 1, commenter = "alice", body = "It's better than I thought!" }) })
```

View the comment information again:

```lua
Send({ Target = ao.id, Tags = { Action = "GetComment" }, Data = json.encode({ article_id = 1, comment_seq_id = 1 }) })

Inbox[#Inbox]
```

You should be able to see that the content of the comment has been updated.

Remove the comment you just posted:

```lua
Send({ Target = ao.id, Tags = { Action = "RemoveComment" }, Data = json.encode({ article_id = 1, version = 4, comment_seq_id = 1 }) })
```

View the comment information again:

```lua
Send({ Target = ao.id, Tags = { Action = "GetComment" }, Data = json.encode({ article_id = 1, comment_seq_id = 1 }) })

Inbox[#Inbox]
```

You should see output similar to this:

```text
New Message From wkD..._XQ: Data = {"error":"ID_NOT_EXI
```

You can view the last message in the inbox again, the complete error code should be `ID_NOT_EXISTS`, which proves that the comment has indeed been removed.

### Test Inventory Item Operations

If you have modified the code after the last `.loal` of the `ai_assisted_ao_dapp_example.lua` file, then you need to reload the application.

We add an inventory item by calling the "Add Inventory Item Entry" method:

```lua
Send({ Target = ao.id, Tags = { Action = "AddInventoryItemEntry" }, Data = json.encode({ inventory_item_id = { product_id = 1, location = "x", inventory_attribute_set = {} }, movement_quantity = 100}) })
```

After the inbox receives the `InventoryItemEntryAdded` event message, you can view the inventory item data like this:

```lua
Send({ Target = ao.id, Tags = { Action = "GetInventoryItem" }, Data = json.encode({ product_id = 1, location = "x", inventory_attribute_set = {} }) })

Inbox[#Inbox]
```

You should see output similar to this:

```text
   Data = "{"result":{"entries":[{"movement_quantity":100,"timestamp":1727689714409}],"version":0,"inventory_item_id":{"location":"x","product_id":1,"inventory_attribute_set":[]},"quantity":100}}",
```

Let's add to the quantity of the inventory item again through "Add Inventory Item Entry":

```lua
Send({ Target = ao.id, Tags = { Action = "AddInventoryItemEntry" }, Data = json.encode({ inventory_item_id = { product_id = 1, location = "x" ,inventory_attribute_set = {} }, movement_quantity = 130, version = 0}) })
```

Wait for the inbox to receive the `InventoryItemEntryAdded` event message, then view the inventory item data again:

```lua
Send({ Target = ao.id, Tags = { Action = "GetInventoryItem" }, Data = json.encode({ product_id = 1, location = "x", inventory_attribute_set = {} }) })

Inbox[#Inbox]
```

Now you should see output similar to this:

```text
   Data = "{"result":{"entries":[{"movement_quantity":100,"timestamp":1727689714409},{"movement_quantity":130,"timestamp":1727689995779}],"inventory_item_id":{"location":"x","product_id":1,"inventory_attribute_set":[]},"version":1,"quantity":230}}",
```

You can see that the quantity of the inventory item has been updated to 230 (`"quantity":230`).

## Further Reading

### More Complex Examples of Low-Code Development for AO Dapps

Our low-code tools can now do more for AO Dapp development than the examples demonstrated above.
Here's a more complex example: https://github.com/dddappp/A-AO-Demo/blob/main/README.md

The most exciting thing about this example is that it shows how to use DSL to orchestrate [SAGA](https://microservices.io/patterns/data/saga.html) processes for achieving "eventual consistency", and generate the implementation code of the SAGA.
If given a choice, I don't think any developer would want to write code to implement SAGA processes manually. `:-)`


#### Using dddappp to Develop a Sui Fully On-Chain Game

This is a production-grade real-world example: https://github.com/wubuku/infinite-sea


### Sui Blog Example

Code repository: https://github.com/dddappp/sui-blog-example

With just about 30 lines of code (all domain model descriptions) - without developers needing to write any other code - you can generate a blog with one click;
A development experience similar to the [RoR Getting Started Guide](https://guides.rubyonrails.org/getting_started.html),
Especially, without writing a single line of code, the 100% automatically generated off-chain query service (sometimes we call it indexer) has many out-of-the-box features.


### Aptos Blog Example

The [Aptos version](https://github.com/dddappp/aptos-blog-example) of the blog example above.


### Sui Crowdfunding Dapp

An crowdfunding Dapp for educational demonstration purposes:

https://github.com/dddappp/sui-crowdfunding-example

