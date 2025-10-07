--- Updates the body of an article
--
-- @module article_update_body_logic

local article = require("article")

local article_update_body_logic = {}


--- Verifies the Article.UpdateBody command.
-- @param _state table The current state of the Article
-- @param body string 
-- @param cmd table The command
-- @param msg any The original message. Properties of an AO msg may include `Timestamp`, `Block-Height`, `Owner`, `Nonce`, etc.
-- @param env table The environment context
-- @return table The event, can use `article.new_article_body_updated` to create it
function article_update_body_logic.verify(_state, body, cmd, msg, env)
    --- TODO: Before returning the event, we can check the arguments; 
    -- if there are illegal arguments, throw error
    -- NOTE: Do not arbitrarily add parameters to functions or fields to structs.
    return article.new_article_body_updated(
        _state, -- type: table
        body -- type: string
    )
end

--- Applies the event to the current state and returns the updated state.
-- @param state table The current state of the Article
-- @param event table The event
-- @param msg any The original message. Properties of an AO msg may include `Timestamp`, `Block-Height`, `Owner`, `Nonce`, etc.
-- @param env any The environment context
-- @return table The updated state of the Article
function article_update_body_logic.mutate(state, event, msg, env)
    --- TODO: Update the current state with the event properties then return it
    -- state.{STATE_PROPERTY} = event.{EVENT_PROPERTY}
    -- return state
    --
    --- Alternatively, you can choose to return a recreated state:
    --[[
    return article.new(
        title, -- type: string
        body, -- type: string
        author -- type: string
    )
    ]]
    --- There is some overhead in creating new objects. 
    -- However, this approach does not modify the original state, 
    -- and it is possible that other parts of the code depend on the invariance of the original state - although this is unlikely to happen.
    --
end

return article_update_body_logic
