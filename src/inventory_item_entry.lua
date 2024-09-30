--- Module for InventoryItemEntry
-- The module includes functions for creating new InventoryItemEntry objects, 
-- converting them to and from key arrays for storage or transmission purposes.
--
-- @module inventory_item_entry

local inventory_item_entry = {}

function inventory_item_entry.new(movement_quantity, timestamp)
    local val = {
        movement_quantity = movement_quantity,
        timestamp = timestamp,
    }
    return val
end

function inventory_item_entry.to_key_array(val)
    return {
        val and val.movement_quantity or nil,
        val and val.timestamp or nil,
    }
end

function inventory_item_entry.from_key_array(key_array)
    return inventory_item_entry.new(
        key_array and key_array[1] or nil,
        key_array and key_array[2] or nil
    )
end

return inventory_item_entry
