local entity_coll = require("entity_coll")
local article_update_body_logic = require("article_update_body_logic")
local article_create_logic = require("article_create_logic")
local article_update_logic = require("article_update_logic")
local article_add_comment_logic = require("article_add_comment_logic")
local article_update_comment_logic = require("article_update_comment_logic")
local article_remove_comment_logic = require("article_remove_comment_logic")
local comment_coll = require("comment_coll")

local article_aggregate = {}

local ERRORS = {
    NIL_ENTITY_ID_SEQUENCE = "NIL_ENTITY_ID_SEQUENCE",
    ENTITY_ID_MISMATCH = "ENTITY_ID_MISMATCH",
    CONCURRENCY_CONFLICT = "CONCURRENCY_CONFLICT",
    VERSION_MISMATCH = "VERSION_MISMATCH",
}

article_aggregate.ERRORS = ERRORS

local article_table
local comment_table
local article_id_sequence

local function current_article_id()
    if (article_id_sequence == nil) then
        error(ERRORS.NIL_ENTITY_ID_SEQUENCE)
    end
    return article_id_sequence[1]
end

local function next_article_id()
    if (article_id_sequence == nil) then
        error(ERRORS.NIL_ENTITY_ID_SEQUENCE)
    end
    article_id_sequence[1] = article_id_sequence[1] + 1
    return article_id_sequence[1]
end


function article_aggregate.init(table, seq, _comment_table)
    article_table = table
    article_id_sequence = seq
    comment_table = _comment_table
end

function article_aggregate.update_body(cmd, msg, env)
    local _state = entity_coll.get_copy(article_table, cmd.article_id)
    if (_state.version ~= cmd.version) then
        error(ERRORS.CONCURRENCY_CONFLICT)
    end
    local article_id = _state.article_id
    local version = _state.version
    _state.comments = comment_coll.new(comment_table, article_id)
    local _event = article_update_body_logic.verify(_state, cmd.body, cmd, msg, env)
    if (_event.article_id ~= article_id) then
        error(ERRORS.ENTITY_ID_MISMATCH)
    end
    if (_event.version ~= version) then
        error(ERRORS.VERSION_MISMATCH)
    end
    local _new_state = article_update_body_logic.mutate(_state, _event, msg, env)
    _new_state.article_id = article_id
    _new_state.version = (version and version or 0) + 1
    local commit = function()
        entity_coll.update(article_table, article_id, _new_state)
        _state.comments:commit()
        _state.comments = nil
    end

    return _event, commit
end

function article_aggregate.create(cmd, msg, env)
    local article_id = next_article_id()
    local _event = article_create_logic.verify(article_id, cmd.title, cmd.body, cmd, msg, env)
    if (_event.article_id ~= current_article_id()
        or _event.article_id ~= article_id
    ) then
        error(ERRORS.ENTITY_ID_MISMATCH)
    end
    local _state = article_create_logic.new(_event, msg, env)
    _state.article_id = _event.article_id
    local commit = function()
        entity_coll.add(article_table, article_id, _state)
        if (_state.comments) then
            _state.comments:commit()
            _state.comments = nil
        end
    end

    return _event, commit
end

function article_aggregate.update(cmd, msg, env)
    local _state = entity_coll.get_copy(article_table, cmd.article_id)
    if (_state.version ~= cmd.version) then
        error(ERRORS.CONCURRENCY_CONFLICT)
    end
    local article_id = _state.article_id
    local version = _state.version
    _state.comments = comment_coll.new(comment_table, article_id)
    local _event = article_update_logic.verify(_state, cmd.title, cmd.body, cmd, msg, env)
    if (_event.article_id ~= article_id) then
        error(ERRORS.ENTITY_ID_MISMATCH)
    end
    if (_event.version ~= version) then
        error(ERRORS.VERSION_MISMATCH)
    end
    local _new_state = article_update_logic.mutate(_state, _event, msg, env)
    _new_state.article_id = article_id
    _new_state.version = (version and version or 0) + 1
    local commit = function()
        entity_coll.update(article_table, article_id, _new_state)
        _state.comments:commit()
        _state.comments = nil
    end

    return _event, commit
end

function article_aggregate.add_comment(cmd, msg, env)
    local _state = entity_coll.get_copy(article_table, cmd.article_id)
    if (_state.version ~= cmd.version) then
        error(ERRORS.CONCURRENCY_CONFLICT)
    end
    local article_id = _state.article_id
    local version = _state.version
    _state.comments = comment_coll.new(comment_table, article_id)
    local _event = article_add_comment_logic.verify(_state, cmd.commenter, cmd.body, cmd, msg, env)
    if (_event.article_id ~= article_id) then
        error(ERRORS.ENTITY_ID_MISMATCH)
    end
    if (_event.version ~= version) then
        error(ERRORS.VERSION_MISMATCH)
    end
    local _new_state = article_add_comment_logic.mutate(_state, _event, msg, env)
    _new_state.article_id = article_id
    _new_state.version = (version and version or 0) + 1
    local commit = function()
        entity_coll.update(article_table, article_id, _new_state)
        _state.comments:commit()
        _state.comments = nil
    end

    return _event, commit
end

function article_aggregate.update_comment(cmd, msg, env)
    local _state = entity_coll.get_copy(article_table, cmd.article_id)
    if (_state.version ~= cmd.version) then
        error(ERRORS.CONCURRENCY_CONFLICT)
    end
    local article_id = _state.article_id
    local version = _state.version
    _state.comments = comment_coll.new(comment_table, article_id)
    local _event = article_update_comment_logic.verify(_state, cmd.comment_seq_id, cmd.commenter, cmd.body, cmd, msg, env)
    if (_event.article_id ~= article_id) then
        error(ERRORS.ENTITY_ID_MISMATCH)
    end
    if (_event.version ~= version) then
        error(ERRORS.VERSION_MISMATCH)
    end
    local _new_state = article_update_comment_logic.mutate(_state, _event, msg, env)
    _new_state.article_id = article_id
    _new_state.version = (version and version or 0) + 1
    local commit = function()
        entity_coll.update(article_table, article_id, _new_state)
        _state.comments:commit()
        _state.comments = nil
    end

    return _event, commit
end

function article_aggregate.remove_comment(cmd, msg, env)
    local _state = entity_coll.get_copy(article_table, cmd.article_id)
    if (_state.version ~= cmd.version) then
        error(ERRORS.CONCURRENCY_CONFLICT)
    end
    local article_id = _state.article_id
    local version = _state.version
    _state.comments = comment_coll.new(comment_table, article_id)
    local _event = article_remove_comment_logic.verify(_state, cmd.comment_seq_id, cmd, msg, env)
    if (_event.article_id ~= article_id) then
        error(ERRORS.ENTITY_ID_MISMATCH)
    end
    if (_event.version ~= version) then
        error(ERRORS.VERSION_MISMATCH)
    end
    local _new_state = article_remove_comment_logic.mutate(_state, _event, msg, env)
    _new_state.article_id = article_id
    _new_state.version = (version and version or 0) + 1
    local commit = function()
        entity_coll.update(article_table, article_id, _new_state)
        _state.comments:commit()
        _state.comments = nil
    end

    return _event, commit
end

return article_aggregate
