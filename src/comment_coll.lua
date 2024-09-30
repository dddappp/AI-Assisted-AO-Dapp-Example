local json = require("json")
local article_comment_id = require("article_comment_id")
local entity_coll = require("entity_coll")

local comment_coll = {}
comment_coll.__index = comment_coll

-- Private constants
local OPERATIONS = {
    ADD = "A",
    UPDATE = "U",
    ADD_OR_UPDATE = "AU",
    REMOVE = "R"
}

-- Create a new comment_coll instance
function comment_coll.new(data_table, article_id)
    local self = setmetatable({}, comment_coll)
    self.data_table = data_table or {}
    self.article_id = article_id
    self.operation_cache = {}
    return self
end

-- Deep copy (private function)
local function deepcopy(origin)
    return entity_coll.deepcopy(origin)
end

-- Check if an entity exists
function comment_coll:contains(comment_seq_id)
    local _article_comment_id = article_comment_id.new(self.article_id, comment_seq_id)
    return entity_coll.contains(self.data_table, json.encode(article_comment_id.to_key_array(_article_comment_id)))
end

-- Add an entity
function comment_coll:add(comment_seq_id, value)
    local _article_comment_id = article_comment_id.new(self.article_id, comment_seq_id)
    table.insert(self.operation_cache,
        { op = OPERATIONS.ADD, key = json.encode(article_comment_id.to_key_array(_article_comment_id)), value = value })
end

-- Update an entity
function comment_coll:update(comment_seq_id, value)
    local _article_comment_id = article_comment_id.new(self.article_id, comment_seq_id)
    table.insert(self.operation_cache,
        { op = OPERATIONS.UPDATE, key = json.encode(article_comment_id.to_key_array(_article_comment_id)), value = value })
end

-- Add or update an entity
function comment_coll:add_or_update(comment_seq_id, value)
    local _article_comment_id = article_comment_id.new(self.article_id, comment_seq_id)
    table.insert(self.operation_cache,
        {
            op = OPERATIONS.ADD_OR_UPDATE,
            key = json.encode(article_comment_id.to_key_array(_article_comment_id)),
            value =
                value
        })
end

-- Remove an entity
function comment_coll:remove(comment_seq_id)
    local _article_comment_id = article_comment_id.new(self.article_id, comment_seq_id)
    table.insert(self.operation_cache,
        { op = OPERATIONS.REMOVE, key = json.encode(article_comment_id.to_key_array(_article_comment_id)) })
end

-- Get a deep copy of an entity
function comment_coll:get(comment_seq_id)
    local _article_comment_id = article_comment_id.new(self.article_id, comment_seq_id)
    local value = entity_coll.get(self.data_table, json.encode(article_comment_id.to_key_array(_article_comment_id)))
    return deepcopy(value)
end

-- Commit all cached operations
function comment_coll:commit()
    for _, operation in ipairs(self.operation_cache) do
        if operation.op == OPERATIONS.ADD then
            entity_coll.add(self.data_table, operation.key, operation.value)
        elseif operation.op == OPERATIONS.UPDATE then
            entity_coll.update(self.data_table, operation.key, operation.value)
        elseif operation.op == OPERATIONS.ADD_OR_UPDATE then
            entity_coll.add_or_update(self.data_table, operation.key, operation.value)
        elseif operation.op == OPERATIONS.REMOVE then
            entity_coll.remove(self.data_table, operation.key)
        end
    end
    -- Clear the operation cache
    self.operation_cache = {}
end

return comment_coll
