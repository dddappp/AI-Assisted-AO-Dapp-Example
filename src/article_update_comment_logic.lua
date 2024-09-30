--- Implements the Article.UpdateComment method.
--
-- @module article_update_comment_logic

local article = require("article")

local article_update_comment_logic = {}


--- Verifies the Article.UpdateComment command.
-- @param _state table The current state of the Article
-- @param comment_seq_id number 
-- @param commenter string 
-- @param body string 
-- @param cmd table The command
-- @param msg any The original message. Properties of an AO msg may include `Timestamp`, `Block-Height`, `Owner`, `Nonce`, etc.
-- @param env table The environment context
-- @return table The event, can use `article.new_comment_updated` to create it
function article_update_comment_logic.verify(_state, comment_seq_id, commenter, body, cmd, msg, env)
    return article.new_comment_updated(_state, comment_seq_id, commenter, body)
end

--- Applies the event to the current state and returns the updated state.
-- @param state table The current state of the Article
-- @param event table The event
-- @param msg any The original message. Properties of an AO msg may include `Timestamp`, `Block-Height`, `Owner`, `Nonce`, etc.
-- @param env any The environment context
-- @return table The updated state of the Article
function article_update_comment_logic.mutate(state, event, msg, env)
    if not state.comments then
        error(string.format("COMMENTS_NOT_SET (article_id: %s)", tostring(state.article_id)))
    end
    if not state.comments:contains(event.comment_seq_id) then
        error(string.format("COMMENT_NOT_FOUND (article_id: %s, comment_seq_id: %s)",
            tostring(state.article_id), tostring(event.comment_seq_id)))
    end
    state.comments:update(event.comment_seq_id, {
        comment_seq_id = event.comment_seq_id,
        commenter = event.commenter,
        body = event.body,
    })
    return state
end

return article_update_comment_logic
