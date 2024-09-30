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
    local tags = {}
    for _, tag in ipairs(MESSAGE_PASS_THROUGH_TAGS) do
        if request_msg.Tags[tag] then
            tags[tag] = request_msg.Tags[tag]
        end
    end
    if request_msg.Tags[X_TAGS.RESPONSE_ACTION] then
        tags["Action"] = request_msg.Tags[X_TAGS.RESPONSE_ACTION]
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
    if (not messaging.convert_to_boolean(request_msg.Tags[X_TAGS.NO_RESPONSE_REQUIRED])) then
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
