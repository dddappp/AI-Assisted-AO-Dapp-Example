--- Module for InventoryItemId
-- The module includes functions for creating new InventoryItemId objects, 
-- converting them to and from key arrays for storage or transmission purposes.
--
-- @module inventory_item_id
-- @see inventory_attribute_set

local inventory_attribute_set = require("inventory_attribute_set")

local inventory_item_id = {}

function inventory_item_id.new(product_id, location, _inventory_attribute_set)
    local val = {
        product_id = product_id,
        location = location,
        inventory_attribute_set = _inventory_attribute_set,
    }
    return val
end

function inventory_item_id.to_key_array(val)
    return {
        val and val.product_id or nil,
        val and val.location or nil,
        inventory_attribute_set.to_key_array(val and val.inventory_attribute_set or nil),
    }
end

function inventory_item_id.from_key_array(key_array)
    return inventory_item_id.new(
        key_array and key_array[1] or nil,
        key_array and key_array[2] or nil,
        inventory_attribute_set.from_key_array(key_array and key_array[3] or nil)
    )
end

return inventory_item_id
