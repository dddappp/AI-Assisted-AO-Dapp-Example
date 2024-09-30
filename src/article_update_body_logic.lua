--- Updates the body of an article
--
-- @module article_update_body_logic

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
