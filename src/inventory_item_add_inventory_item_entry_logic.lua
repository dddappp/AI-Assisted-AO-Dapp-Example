--- Implements the InventoryItem.AddInventoryItemEntry method.
--
-- @module inventory_item_add_inventory_item_entry_logic

local inventory_item = require("inventory_item")

local inventory_item_add_inventory_item_entry_logic = {}


--- Verifies the InventoryItem.AddInventoryItemEntry command.
-- @param _state table The current state of the InventoryItem. Maybe nil.
-- @param inventory_item_id table The InventoryItemId of the InventoryItem
-- @param movement_quantity number 
-- @param cmd table The command
-- @param msg any The original message. Properties of an AO msg may include `Timestamp`, `Block-Height`, `Owner`, `Nonce`, etc.
-- @param env table The environment context
-- @return table The event, can use `inventory_item.new_inventory_item_entry_added` to create it
function inventory_item_add_inventory_item_entry_logic.verify(_state, inventory_item_id, movement_quantity, cmd, msg, env)
    -- Check if movement_quantity is a valid number
    if type(movement_quantity) ~= "number" then
        error("movement_quantity must be a number")
    end

    -- Check if inventory_item_id is a valid table
    if type(inventory_item_id) ~= "table" or 
       type(inventory_item_id.product_id) ~= "number" or
       type(inventory_item_id.location) ~= "string" or
       type(inventory_item_id.inventory_attribute_set) ~= "table" then
        error("Invalid inventory_item_id")
    end

    return inventory_item.new_inventory_item_entry_added(
        inventory_item_id, -- type: table
        _state, -- type: table
        movement_quantity -- type: number
    )
end

--- Applies the event to the current state and returns the updated state.
-- @param state table The current state of the InventoryItem. Maybe nil for the first event.
-- @param event table The event
-- @param msg any The original message. Properties of an AO msg may include `Timestamp`, `Block-Height`, `Owner`, `Nonce`, etc.
-- @param env any The environment context
-- @return table The updated state of the InventoryItem
function inventory_item_add_inventory_item_entry_logic.mutate(state, event, msg, env)
    if not state then
        -- Create a new state if it doesn't exist
        state = inventory_item.new(
            event.inventory_item_id,
            event.movement_quantity,
            {
                {
                    movement_quantity = event.movement_quantity,
                    timestamp = msg.Timestamp or os.time()
                }
            }
        )
    else
        -- Update existing state
        state.quantity = state.quantity + event.movement_quantity
        table.insert(state.entries, {
            movement_quantity = event.movement_quantity,
            timestamp = msg.Timestamp or os.time()
        })
    end

    return state
end

return inventory_item_add_inventory_item_entry_logic
