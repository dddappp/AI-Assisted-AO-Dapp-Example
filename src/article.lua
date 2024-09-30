local article = {}

local ERRORS = {
}

article.ERRORS = ERRORS


--- Creates a new Article state.
--
-- @param title string 
-- @param body string 
-- @param author string 
-- @return table A new state table representing the Article.
function article.new(title, body, author)
    local state = {
        version = 0,
        title = title,
        body = body,
        author = author,
    }
    return state
end

--- Creates a new ArticleBodyUpdated event.
-- @param _state table The current state of the Article
-- @param body string 
-- @return table
function article.new_article_body_updated(_state, body)
    local event = {}
    event.event_type = "ArticleBodyUpdated"
    event.article_id = _state.article_id
    event.version = _state.version
    event.body = body
    return event
end

--- Creates a new ArticleCreated event.
-- @param article_id number The ArticleId of the Article
-- @param title string 
-- @param body string 
-- @param author string 
-- @return table
function article.new_article_created(article_id, title, body, author)
    local event = {}
    event.event_type = "ArticleCreated"
    event.article_id = article_id
    event.title = title
    event.body = body
    event.author = author
    return event
end

--- Creates a new ArticleUpdated event.
-- @param _state table The current state of the Article
-- @param title string 
-- @param body string 
-- @return table
function article.new_article_updated(_state, title, body)
    local event = {}
    event.event_type = "ArticleUpdated"
    event.article_id = _state.article_id
    event.version = _state.version
    event.title = title
    event.body = body
    return event
end

--- Creates a new CommentAdded event.
-- @param _state table The current state of the Article
-- @param comment_seq_id number 
-- @param commenter string 
-- @param body string 
-- @return table
function article.new_comment_added(_state, comment_seq_id, commenter, body)
    local event = {}
    event.event_type = "CommentAdded"
    event.article_id = _state.article_id
    event.version = _state.version
    event.comment_seq_id = comment_seq_id
    event.commenter = commenter
    event.body = body
    return event
end

--- Creates a new CommentUpdated event.
-- @param _state table The current state of the Article
-- @param comment_seq_id number 
-- @param commenter string 
-- @param body string 
-- @return table
function article.new_comment_updated(_state, comment_seq_id, commenter, body)
    local event = {}
    event.event_type = "CommentUpdated"
    event.article_id = _state.article_id
    event.version = _state.version
    event.comment_seq_id = comment_seq_id
    event.commenter = commenter
    event.body = body
    return event
end

--- Creates a new CommentRemoved event.
-- @param _state table The current state of the Article
-- @param comment_seq_id number 
-- @return table
function article.new_comment_removed(_state, comment_seq_id)
    local event = {}
    event.event_type = "CommentRemoved"
    event.article_id = _state.article_id
    event.version = _state.version
    event.comment_seq_id = comment_seq_id
    return event
end

return article
