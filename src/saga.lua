local entity_coll = require("entity_coll")

local saga = {}

local ERRORS = {
    NIL_SAGA_ID_SEQUENCE = "NIL_SAGA_ID_SEQUENCE",
    INVALID_STEP = "INVALID_STEP",
}

local saga_instances
local saga_id_sequence


function saga.init(_saga_instances, _saga_id_sequence)
    saga_instances = _saga_instances
    saga_id_sequence = _saga_id_sequence
end

local function next_saga_id()
    if (saga_id_sequence == nil) then
        error(ERRORS.NIL_SAGA_ID_SEQUENCE)
    end
    saga_id_sequence[1] = saga_id_sequence[1] + 1
    return saga_id_sequence[1]
end

function saga.get_saga_instance(saga_id)
    return entity_coll.get(saga_instances, saga_id)
end

function saga.get_saga_instance_copy(saga_id)
    return entity_coll.get_copy(saga_instances, saga_id)
end

function saga.contains_saga_instance(saga_id)
    return entity_coll.contains(saga_instances, saga_id)
end

function saga.create_saga_instance(saga_type, target, tags, context, original_message, local_steps)
    local saga_id = next_saga_id()
    local saga_instance = {
        saga_id = saga_id,
        saga_type = saga_type,
        current_step = 1,
        compensating = false,
        completed = false,
        participants = {},
        compensations = {},
        context = context,
        original_message = original_message,
    }
    if (local_steps) then
        for i = 1, local_steps, 1 do
            saga_instance.current_step = saga_instance.current_step + 1
            saga_instance.participants[#saga_instance.participants + 1] = {} -- invoke local
        end
    end
    saga_instance.participants[#saga_instance.participants + 1] = {
        {
            target = target,
            tags = tags,
        },
    }

    local commit = function()
        entity_coll.add(saga_instances, saga_id, saga_instance)
    end
    return saga_instance, commit
end

function saga.set_instance_compensating(saga_id, steps_upward)
    local saga_instance = saga.get_saga_instance_copy(saga_id)
    saga_instance.current_step = saga_instance.current_step + steps_upward
    saga_instance.compensating = true
    local commit = function()
        entity_coll.update(saga_instances, saga_id, saga_instance)
    end
    return commit
end

--- Move saga instance's current_step forward and record participant information
function saga.move_saga_instance_forward(saga_id, steps, target, tags, context)
    if (type(steps) ~= "number" or steps < 1) then
        error(ERRORS.INVALID_STEP)
    end
    local saga_instance = saga.get_saga_instance_copy(saga_id)
    for _ = 1, steps - 1, 1 do
        saga_instance.current_step = saga_instance.current_step + 1
        saga_instance.participants[saga_instance.current_step] = {} -- invoke local
    end
    saga_instance.current_step = saga_instance.current_step + 1
    saga_instance.participants[saga_instance.current_step] = {
        target = target,
        tags = tags,
    }
    saga_instance.context = context
    local commit = function()
        entity_coll.update(saga_instances, saga_id, saga_instance)
    end
    return commit
end

function saga.rollback_saga_instance(saga_id, steps, compensation_target, compensation_tags, context, _err)
    if (type(steps) ~= "number" or steps < 0) then
        error(ERRORS.INVALID_STEP)
    end
    local saga_instance = saga.get_saga_instance_copy(saga_id)
    saga_instance.compensating = true
    for _ = 1, steps - 1, 1 do
        saga_instance.current_step = saga_instance.current_step - 1
        saga_instance.compensations[#saga_instance.compensations + 1] = {} -- "invokeLocal" or empty compensation
    end
    if (saga_instance.current_step <= 1) then
        -- Let current_step stop at 1
        saga_instance.completed = true
    elseif (saga_instance.current_step > 1) then
        saga_instance.current_step = saga_instance.current_step - 1
        if (saga_instance.current_step <= 1) then
            saga_instance.completed = true
        end
        if (compensation_target) then
            saga_instance.compensations[#saga_instance.compensations + 1] = {
                target = compensation_target,
                tags = compensation_tags or {},
            }
        else
            saga_instance.compensations[#saga_instance.compensations + 1] = {}
        end
    else -- if (saga_instance.current_step == 1) then
        -- do nothing
    end
    if context then
        saga_instance.context = context
    end
    if _err then
        saga_instance.error = tostring(_err)
    end
    local commit = function()
        entity_coll.update(saga_instances, saga_id, saga_instance)
    end
    return commit
end

--- Complete saga instance
function saga.complete_saga_instance(saga_id, result, context, steps_upward)
    local saga_instance = saga.get_saga_instance_copy(saga_id)
    saga_instance.completed = true
    if (steps_upward) then
        saga_instance.current_step = saga_instance.current_step + steps_upward
    end
    if (result) then
        saga_instance.result = result
    end
    if (context) then
        saga_instance.context = context
    end
    local commit = function()
        entity_coll.update(saga_instances, saga_id, saga_instance)
    end
    return commit
end

return saga
