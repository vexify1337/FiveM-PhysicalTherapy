local bridge = {
    framework = nil
}

local QBCore = nil
local ESX = nil

local function resource_started(name)
    return GetResourceState(name) == 'started'
end

CreateThread(function()
    Wait(Config.detection_delay)
    if resource_started(Config.frameworks.qb_core) then
        bridge.framework = Config.frameworks.qb_core
        QBCore = exports[Config.frameworks.qb_core]:GetCoreObject()
    elseif resource_started(Config.frameworks.es_extended) then
        bridge.framework = Config.frameworks.es_extended
        ESX = exports[Config.frameworks.es_extended]:getSharedObject()
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

exports('notify', function(source, message, notify_type, duration)
    if not source or not message then
        return false
    end
    notify_type = notify_type or 'primary'
    duration = duration or 5000
    if bridge.framework == Config.frameworks.qb_core and QBCore then
        TriggerClientEvent('QBCore:Notify', source, message, notify_type, duration)
        return true
    elseif bridge.framework == Config.frameworks.es_extended and ESX then
        TriggerClientEvent('esx:showNotification', source, message)
        return true
    end
    return false
end)
