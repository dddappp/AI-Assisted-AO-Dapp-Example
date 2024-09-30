--- Implements the Article.Update method.
--
-- @module article_update_logic

local article = require("article")

local article_update_logic = {}


--- Verifies the Article.Update command.
-- @param _state table The current state of the Article
-- @param title string 
-- @param body string 
-- @param cmd table The command
-- @param msg any The original message. Properties of an AO msg may include `Timestamp`, `Block-Height`, `Owner`, `Nonce`, etc.
-- @param env table The environment context
-- @return table The event, can use `article.new_article_updated` to create it
function article_update_logic.verify(_state, title, body, cmd, msg, env)
    return article.new_article_updated(_state, title, body)
end

--- Applies the event to the current state and returns the updated state.
-- @param state table The current state of the Article
-- @param event table The event
-- @param msg any The original message. Properties of an AO msg may include `Timestamp`, `Block-Height`, `Owner`, `Nonce`, etc.
-- @param env any The environment context
-- @return table The updated state of the Article
function article_update_logic.mutate(state, event, msg, env)
    state.title = event.title
    state.body = event.body
    return state
end

return article_update_logic
