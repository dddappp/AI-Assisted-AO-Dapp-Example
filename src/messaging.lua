local json = require("json")

local messaging = {}

local X_TAGS = {
    NO_RESPONSE_REQUIRED = "X-NoResponseRequired",
    RESPONSE_ACTION = "X-ResponseAction",
    SAGA_ID = "X-SagaId",
}

local MESSAGE_PASS_THROUGH_TAGS = {
    X_TAGS.SAGA_ID,
}

messaging.X_TAGS = X_TAGS
messaging.MESSAGE_PASS_THROUGH_TAGS = MESSAGE_PASS_THROUGH_TAGS

-- Embed saga information in data to avoid tag loss during forwarding
function messaging.embed_saga_info_in_data(data, saga_id, response_action)
    local enhanced_data = data or {}
    enhanced_data[messaging.X_TAGS.SAGA_ID] = saga_id
    enhanced_data[messaging.X_TAGS.RESPONSE_ACTION] = response_action
    return enhanced_data
end

-- Extract saga information from data
function messaging.extract_saga_info_from_data(data)
    if type(data) == "string" then
        data = json.decode(data)
    end
    return data[messaging.X_TAGS.SAGA_ID], data[messaging.X_TAGS.RESPONSE_ACTION]
end

-- DDDML Enhancement: Saga information access functions
-- Based on data embedding mechanism (the only reliable cross-process transmission method)
function messaging.get_saga_id(msg)
    -- Extract saga information only from data (cross-process safe)
    return messaging.extract_saga_info_from_data(msg.Data)
end

function messaging.get_response_action(msg)
    -- Extract response action only from data (cross-process safe)
    local _, response_action = messaging.extract_saga_info_from_data(msg.Data)
    return response_action
end

function messaging.get_no_response_required(msg)
    -- DDDML Enhancement: Extract from data embedding (not used yet, for compatibility)
    return nil  -- Currently no_response_required is not embedded in data
end

local string_to_boolean_mappings = {
    ["true"] = true,
    ["false"] = false,
    ["yes"] = true,
    ["no"] = false,
    ["1"] = true,
    ["0"] = false
}

function messaging.convert_to_boolean(val)
    if (type(val) == "string") then
        return string_to_boolean_mappings[val:lower()] or false
    end
    if (type(val) == "number") then
        return val ~= 0
    end
    return (val and true) or false
end

function messaging.extract_error_code(err)
    if (err == nil or err == '') then
        return "INTERNAL_ERROR"
    end
    local err_msg = tostring(err)
    return err_msg:match("%s+([%u_]+)[^%s]*$") or err_msg
end

function messaging.respond(status, result_or_error, request_msg)
    local data = status and { result = result_or_error } or { error = messaging.extract_error_code(result_or_error) };

    local saga_id = messaging.get_saga_id(request_msg)
    local response_action = messaging.get_response_action(request_msg)

    local tags = {}
    if response_action then
        tags["Action"] = response_action
    end

    -- Embed saga information in response data if available
    if saga_id then
        data = messaging.embed_saga_info_in_data(data, saga_id, response_action)
    end

    ao.send({
        Target = request_msg.From,
        Data = json.encode(data),
        Tags = tags
    })
end

function messaging.handle_response_based_on_tag(status, result_or_error, commit, request_msg)
    if status then
        commit()
    end
    if (not messaging.convert_to_boolean(messaging.get_no_response_required(request_msg))) then
        messaging.respond(status, result_or_error, request_msg)
    else
        if not status then
            error(result_or_error)
        end
    end
end

local function send(target, data, tags)
    ao.send({
        Target = target,
        Data = json.encode(data),
        Tags = tags
    })
end

function messaging.commit_send_or_error(status, request_or_error, commit, target, tags)
    if (status) then
        commit()
        send(target, request_or_error, tags)
    else
        error(request_or_error)
    end
end

return messaging
