local ESX = nil
local QBCore = nil
local Framework = nil

CreateThread(function()
    Wait(100)
    if GetResourceState('es_extended') ~= 'missing' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'
        print('^2[FearX-NpcCrutchRemover]^7 Detected ESX Framework')
    elseif GetResourceState('qb-core') ~= 'missing' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb'
        print('^2[FearX-NpcCrutchRemover]^7 Detected QBCore Framework')
    else
        print('^1[FearX-NpcCrutchRemover]^7 No framework detected!')
    end
end)

-- edited by solph: original script had ZERO money handling for QBCore, it would just return 0 and break everything :0 now it actually works
local function GetPlayerMoney(source, account)
    if GetResourceState('s6la_bridge') == 'started' then
        local bridge = exports['s6la_bridge']:ret_bridge_table()
        if bridge and bridge.framework then
            if bridge.framework == 'qb-core' then
                local Player = QBCore.Functions.GetPlayer(source)
                if Player then
                    return Player.Functions.GetMoney(account or 'cash')
                end
            elseif bridge.framework == 'es_extended' then
                local xPlayer = ESX.GetPlayerFromId(source)
                if xPlayer then
                    if account == 'cash' then
                        return xPlayer.getMoney()
                    else
                        return xPlayer.getAccount('bank').money
                    end
                end
            end
        end
    end
    
    if Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if account == 'cash' then
                if GetResourceState('ox_inventory') == 'started' then
                    local oxMoney = exports.ox_inventory:Search(source, 'count', 'money')
                    if oxMoney and oxMoney > 0 then
                        return oxMoney
                    end
                end
                return xPlayer.getMoney()
            else
                return xPlayer.getAccount('bank').money
            end
        end
    elseif Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.Functions.GetMoney(account or 'cash')
        end
    end
    return 0
end

-- edited by solph: original script couldn't remove money from QBCore players at all, now it actually works and uses proper reason parameter..
local function RemovePlayerMoney(source, amount, account)
    if GetResourceState('s6la_bridge') == 'started' then
        local bridge = exports['s6la_bridge']:ret_bridge_table()
        if bridge and bridge.framework then
            if bridge.framework == 'qb-core' then
                local Player = QBCore.Functions.GetPlayer(source)
                if Player then
                    local has_money = Player.Functions.GetMoney(account or 'cash')
                    if has_money >= amount then
                        Player.Functions.RemoveMoney(account or 'cash', amount, 'physical-therapy')
                        return true
                    end
                end
            elseif bridge.framework == 'es_extended' then
                local xPlayer = ESX.GetPlayerFromId(source)
                if xPlayer then
                    if account == 'cash' then
                        if xPlayer.getMoney() >= amount then
                            xPlayer.removeMoney(amount)
                            return true
                        end
                    else
                        if xPlayer.getAccount('bank').money >= amount then
                            xPlayer.removeAccountMoney('bank', amount)
                            return true
                        end
                    end
                end
            end
        end
    end
    
    if Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if account == 'cash' then
                if GetResourceState('ox_inventory') == 'started' then
                    local oxMoney = exports.ox_inventory:Search(source, 'count', 'money')
                    if oxMoney and oxMoney >= amount then
                        exports.ox_inventory:RemoveItem(source, 'money', amount)
                        return true
                    end
                end
                if xPlayer.getMoney() >= amount then
                    xPlayer.removeMoney(amount)
                    return true
                end
            else
                if xPlayer.getAccount('bank').money >= amount then
                    xPlayer.removeAccountMoney('bank', amount)
                    return true
                end
            end
        end
    elseif Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            local has_money = Player.Functions.GetMoney(account or 'cash')
            if has_money >= amount then
                Player.Functions.RemoveMoney(account or 'cash', amount, 'physical-therapy')
                return true
            end
        end
    end
    return false
end

-- edited by solph: added validation because original script would accept negative prices and crash, now it's actually secure :0
lib.callback.register('fearx-crutchremover:canAfford', function(source, price)
    if not source or type(source) ~= 'number' or source <= 0 then
        return false
    end
    if not price or type(price) ~= 'number' or price < 0 then
        return false
    end
    local money = GetPlayerMoney(source, Config.MoneyAccount)
    return money >= price
end)

-- edited by solph: added validation and proper error handling because original would just silently fail and confuse players
lib.callback.register('fearx-crutchremover:chargeMoney', function(source, price)
    if not source or type(source) ~= 'number' or source <= 0 then
        return false
    end
    if not price or type(price) ~= 'number' or price < 0 then
        return false
    end
    if Config.MoneyAccount ~= 'cash' and Config.MoneyAccount ~= 'bank' then
        return false
    end
    local success = RemovePlayerMoney(source, price, Config.MoneyAccount)
    return success
end)
