local bridge = {
    framework = nil
}

local function resource_started(name)
    return GetResourceState(name) == 'started'
end

CreateThread(function()
    Wait(Config.detection_delay)
    if resource_started(Config.frameworks.qb_core) then
        bridge.framework = Config.frameworks.qb_core
    elseif resource_started(Config.frameworks.es_extended) then
        bridge.framework = Config.frameworks.es_extended
    else
        bridge.framework = 'unknown'
    end
    if Config.debug then
        print('[S6LABridge] framework: ' .. bridge.framework)
    end
end)

exports('ret_bridge_table', function()
    return bridge
end)

exports('notify', function(message, notify_type, duration)
    if not message then
        return false
    end
    notify_type = notify_type or 'primary'
    duration = duration or 5000
    if bridge.framework == Config.frameworks.qb_core then
        TriggerEvent('QBCore:Notify', message, notify_type, duration)
        return true
    elseif bridge.framework == Config.frameworks.es_extended then
        TriggerEvent('esx:showNotification', message)
        return true
    end
    return false
end)
