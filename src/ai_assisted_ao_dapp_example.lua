ArticleTable = ArticleTable and (
    function(old_data)
        -- May need to migrate old data
        return old_data
    end
)(ArticleTable) or {}

ArticleIdSequence = ArticleIdSequence and (
    function(old_data)
        -- May need to migrate old data
        return old_data
    end
)(ArticleIdSequence) or { 0 }

CommentTable = CommentTable and (
    function(old_data)
        -- May need to migrate old data
        return old_data
    end
)(CommentTable) or {}


SagaInstances = SagaInstances and (
    function(old_data)
        -- May need to migrate old data
        return old_data
    end
)(SagaInstances) or {}

SagaIdSequence = SagaIdSequence and (
    function(old_data)
        -- May need to migrate old data
        return old_data
    end
)(SagaIdSequence) or { 0 }


local json = require("json")
local entity_coll = require("entity_coll")
local messaging = require("messaging")
local saga = require("saga")
local article_comment_id = require("article_comment_id")
local article_aggregate = require("article_aggregate")

article_aggregate.init(ArticleTable, ArticleIdSequence, CommentTable)

saga.init(SagaInstances, SagaIdSequence)


local function get_article(msg, env, response)
    local status, result = pcall((function()
        local article_id = json.decode(msg.Data)
        local _state = entity_coll.get(ArticleTable, article_id)
        return _state
    end))
    messaging.respond(status, result, msg)
end

local function get_comment(msg, env, response)
    local status, result = pcall((function()
        local _article_comment_id = json.decode(msg.Data)
        local _key = json.encode(article_comment_id.to_key_array(_article_comment_id))
        local _state = entity_coll.get(CommentTable, _key)
        return _state
    end))
    messaging.respond(status, result, msg)
end

local function update_article_body(msg, env, response)
    local status, result, commit = pcall((function()
        local cmd = json.decode(msg.Data)
        return article_aggregate.update_body(cmd, msg, env)
    end))
    messaging.handle_response_based_on_tag(status, result, commit, msg)
end

local function create_article(msg, env, response)
    local status, result, commit = pcall((function()
        local cmd = json.decode(msg.Data)
        return article_aggregate.create(cmd, msg, env)
    end))
    messaging.handle_response_based_on_tag(status, result, commit, msg)
end

local function update_article(msg, env, response)
    local status, result, commit = pcall((function()
        local cmd = json.decode(msg.Data)
        return article_aggregate.update(cmd, msg, env)
    end))
    messaging.handle_response_based_on_tag(status, result, commit, msg)
end

local function add_comment(msg, env, response)
    local status, result, commit = pcall((function()
        local cmd = json.decode(msg.Data)
        return article_aggregate.add_comment(cmd, msg, env)
    end))
    messaging.handle_response_based_on_tag(status, result, commit, msg)
end

local function update_comment(msg, env, response)
    local status, result, commit = pcall((function()
        local cmd = json.decode(msg.Data)
        return article_aggregate.update_comment(cmd, msg, env)
    end))
    messaging.handle_response_based_on_tag(status, result, commit, msg)
end

local function remove_comment(msg, env, response)
    local status, result, commit = pcall((function()
        local cmd = json.decode(msg.Data)
        return article_aggregate.remove_comment(cmd, msg, env)
    end))
    messaging.handle_response_based_on_tag(status, result, commit, msg)
end

Handlers.add(
    "get_article",
    Handlers.utils.hasMatchingTag("Action", "GetArticle"),
    get_article
)

Handlers.add(
    "get_comment",
    Handlers.utils.hasMatchingTag("Action", "GetComment"),
    get_comment
)

Handlers.add(
    "get_article_count",
    Handlers.utils.hasMatchingTag("Action", "GetArticleCount"),
    function(msg, env, response)
        local count = 0
        for _ in pairs(ArticleTable) do
            count = count + 1
        end
        messaging.respond(true, count, msg)
    end
)

Handlers.add(
    "get_article_id_sequence",
    Handlers.utils.hasMatchingTag("Action", "GetArticleIdSequence"),
    function(msg, env, response)
        messaging.respond(true, ArticleIdSequence, msg)
    end
)

Handlers.add(
    "update_article_body",
    Handlers.utils.hasMatchingTag("Action", "UpdateArticleBody"),
    update_article_body
)

Handlers.add(
    "create_article",
    Handlers.utils.hasMatchingTag("Action", "CreateArticle"),
    create_article
)

Handlers.add(
    "update_article",
    Handlers.utils.hasMatchingTag("Action", "UpdateArticle"),
    update_article
)

Handlers.add(
    "add_comment",
    Handlers.utils.hasMatchingTag("Action", "AddComment"),
    add_comment
)

Handlers.add(
    "update_comment",
    Handlers.utils.hasMatchingTag("Action", "UpdateComment"),
    update_comment
)

Handlers.add(
    "remove_comment",
    Handlers.utils.hasMatchingTag("Action", "RemoveComment"),
    remove_comment
)


Handlers.add(
    "get_sage_instance",
    Handlers.utils.hasMatchingTag("Action", "GetSagaInstance"),
    function(msg, env, response)
        local cmd = json.decode(msg.Data)
        local saga_id = cmd.saga_id
        local s = entity_coll.get(SagaInstances, saga_id)
        messaging.respond(true, s, msg)
    end
)


Handlers.add(
    "get_sage_id_sequence",
    Handlers.utils.hasMatchingTag("Action", "GetSagaIdSequence"),
    function(msg, env, response)
        messaging.respond(true, SagaIdSequence, msg)
    end
)


