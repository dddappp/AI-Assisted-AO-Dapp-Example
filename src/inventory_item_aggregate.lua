local entity_coll = require("entity_coll")
local json = require("json")
local inventory_item_id = require("inventory_item_id")
local inventory_item_add_inventory_item_entry_logic = require("inventory_item_add_inventory_item_entry_logic")

local inventory_item_aggregate = {}

local ERRORS = {
    NIL_ENTITY_ID_SEQUENCE = "NIL_ENTITY_ID_SEQUENCE",
    ENTITY_ID_MISMATCH = "ENTITY_ID_MISMATCH",
    CONCURRENCY_CONFLICT = "CONCURRENCY_CONFLICT",
    VERSION_MISMATCH = "VERSION_MISMATCH",
}

inventory_item_aggregate.ERRORS = ERRORS

local inventory_item_table

function inventory_item_aggregate.init(table)
    inventory_item_table = table
end

function inventory_item_aggregate.add_inventory_item_entry(cmd, msg, env)
    local _inventory_item_id = cmd.inventory_item_id
    local _inventory_item_id_key = json.encode(inventory_item_id.to_key_array(_inventory_item_id))
    local _state = entity_coll.get_copy_or_else_nil(inventory_item_table, _inventory_item_id_key)
    if (_state and _state.version ~= cmd.version) then
        error(ERRORS.CONCURRENCY_CONFLICT)
    end
    if (_state) then
        _state.inventory_item_id = _inventory_item_id
    end
    local version = _state and _state.version or nil
    local _event = inventory_item_add_inventory_item_entry_logic.verify(_state, _inventory_item_id, cmd.movement_quantity,
        cmd, msg, env)
    if (_event.inventory_item_id ~= _inventory_item_id) then
        error(ERRORS.ENTITY_ID_MISMATCH)
    end
    if (version and (_event.version ~= version)) then
        error(ERRORS.VERSION_MISMATCH)
    end
    local _new_state = inventory_item_add_inventory_item_entry_logic.mutate(_state, _event, msg, env)
    _new_state.inventory_item_id = _inventory_item_id
    _new_state.version = version and (version + 1) or 0
    local commit = function()
        entity_coll.add_or_update(inventory_item_table, _inventory_item_id_key, _new_state)
    end

    return _event, commit
end

return inventory_item_aggregate
