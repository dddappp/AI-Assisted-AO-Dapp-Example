--- Implements the Article.RemoveComment method.
--
-- @module article_remove_comment_logic

local article = require("article")

local article_remove_comment_logic = {}


--- Verifies the Article.RemoveComment command.
-- @param _state table The current state of the Article
-- @param comment_seq_id number 
-- @param cmd table The command
-- @param msg any The original message. Properties of an AO msg may include `Timestamp`, `Block-Height`, `Owner`, `Nonce`, etc.
-- @param env table The environment context
-- @return table The event, can use `article.new_comment_removed` to create it
function article_remove_comment_logic.verify(_state, comment_seq_id, cmd, msg, env)
    return article.new_comment_removed(_state, comment_seq_id)
end

--- Applies the event to the current state and returns the updated state.
-- @param state table The current state of the Article
-- @param event table The event
-- @param msg any The original message. Properties of an AO msg may include `Timestamp`, `Block-Height`, `Owner`, `Nonce`, etc.
-- @param env any The environment context
-- @return table The updated state of the Article
function article_remove_comment_logic.mutate(state, event, msg, env)
    if not state.comments then
        error(string.format("COMMENTS_NOT_SET (article_id: %s)", tostring(state.article_id)))
    end
    if not state.comments:contains(event.comment_seq_id) then
        error(string.format("COMMENT_NOT_FOUND (article_id: %s, comment_seq_id: %s)",
            tostring(state.article_id), tostring(event.comment_seq_id)))
    end
    state.comments:remove(event.comment_seq_id)
    return state
end

return article_remove_comment_logic
