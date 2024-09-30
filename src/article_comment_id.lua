--- Module for ArticleCommentId
-- The module includes functions for creating new ArticleCommentId objects, 
-- converting them to and from key arrays for storage or transmission purposes.
--
-- @module article_comment_id

local article_comment_id = {}

function article_comment_id.new(article_id, comment_seq_id)
    local val = {
        article_id = article_id,
        comment_seq_id = comment_seq_id,
    }
    return val
end

function article_comment_id.to_key_array(val)
    return {
        val and val.article_id or nil,
        val and val.comment_seq_id or nil,
    }
end

function article_comment_id.from_key_array(key_array)
    return article_comment_id.new(
        key_array and key_array[1] or nil,
        key_array and key_array[2] or nil
    )
end

return article_comment_id
