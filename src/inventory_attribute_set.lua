--- Module for InventoryAttributeSet
-- The module includes functions for creating new InventoryAttributeSet objects, 
-- converting them to and from key arrays for storage or transmission purposes.
--
-- @module inventory_attribute_set

local inventory_attribute_set = {}

function inventory_attribute_set.new(foo, bar)
    local val = {
        foo = foo,
        bar = bar,
    }
    return val
end

function inventory_attribute_set.to_key_array(val)
    return {
        val and val.foo or nil,
        val and val.bar or nil,
    }
end

function inventory_attribute_set.from_key_array(key_array)
    return inventory_attribute_set.new(
        key_array and key_array[1] or nil,
        key_array and key_array[2] or nil
    )
end

return inventory_attribute_set
