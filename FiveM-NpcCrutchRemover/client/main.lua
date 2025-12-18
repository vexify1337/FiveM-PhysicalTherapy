local locationBlips = {}
local spawnedNPCs = {}
local target_system = nil

-- edited by solph: original script only supported ox_target and would crash if you didn't have it :0 which OBVIOUSLY most people wouldnt have on qbcore as its NOT supported..
local function GetTargetSystem()
    if GetResourceState('qb-target') == 'started' then
        return 'qb-target'
    elseif GetResourceState('ox_target') == 'started' then
        return 'ox_target'
    elseif GetResourceState('qtarget') == 'started' then
        return 'qtarget'
    end
    return nil
end


local function CreateLocationBlips()
    for _, location in ipairs(Config.MedicLocations) do
        if location.blip and location.blip.enabled then
            local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
            SetBlipSprite(blip, location.blip.sprite)
            SetBlipColour(blip, location.blip.color)
            SetBlipScale(blip, location.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(location.blip.label)
            EndTextCommandSetBlipName(blip)
            table.insert(locationBlips, blip)
        end
    end
end

local function RemoveLocationBlips()
    for _, blip in ipairs(locationBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    locationBlips = {}
end

local function SpawnNPCs()
    for _, location in ipairs(Config.MedicLocations) do
        local model = GetHashKey(Config.NPCModel)
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(10)
        end

        local npc = CreatePed(0, model, location.coords.x, location.coords.y, location.coords.z - 1.0, location.coords.w, false, true)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        FreezeEntityPosition(npc, true)
        SetPedDiesWhenInjured(npc, false)
        SetPedCanPlayAmbientAnims(npc, true)
        SetPedCanRagdollFromPlayerImpact(npc, false)

        table.insert(spawnedNPCs, npc)
    end
end

local function DeleteNPCs()
    for _, npc in ipairs(spawnedNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    spawnedNPCs = {}
end

local function PlayRemovalAnimation(npc)
    local dict = Config.Animation.dict
    local anim = Config.Animation.anim

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end

    TaskPlayAnim(npc, dict, anim, 8.0, -8.0, Config.Animation.duration, 1, 0, false, false, false)

    local success = lib.progressBar({
        duration = Config.Animation.duration,
        label = 'Receiving physical therapy...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    })

    ClearPedTasks(npc)
    return success
end

-- edited by solph: original had wrong trigger name for ak47_qb_crutch, was using 'ak47_crutch:remove' instead of 'ak47_qb_crutch:remove' smh
local function RemoveCrutch()
    local playerId = GetPlayerServerId(PlayerId())

    if GetResourceState('wasabi_crutch') == 'started' then
        pcall(function()
            exports.wasabi_crutch:RemoveCrutch(playerId)
        end)
    end

    if GetResourceState('ak47_crutch') == 'started' then
        TriggerServerEvent('ak47_crutch:remove', playerId)
    end

    if GetResourceState('ak47_qb_crutch') == 'started' then
        TriggerServerEvent('ak47_qb_crutch:remove', playerId)
    end
end

-- edited by solph: added entity checks because the original would try to interact with deleted NPCs and crash :0 also added proper money validation
local function AttemptCrutchRemoval(npc)
    if not DoesEntityExist(npc) then
        exports['s6la_bridge']:notify('NPC not found', 'error')
        return
    end
    
    local price = Config.ChargeMoney and Config.RemovalPrice or 0

    if Config.ChargeMoney and price > 0 then
        if GetResourceState('ox_lib') ~= 'started' then
            exports['s6la_bridge']:notify('ox_lib is required for this feature', 'error')
            return
        end
        
        local canAfford = lib.callback.await('fearx-crutchremover:canAfford', false, price)
        
        if not canAfford then
            exports['s6la_bridge']:notify(string.format(Config.Notifications.notEnoughMoney, price), 'error')
            return
        end
    end

    local success = PlayRemovalAnimation(npc)

    if not success then
        exports['s6la_bridge']:notify(Config.Notifications.cancelled, 'error')
        return
    end

    if Config.ChargeMoney and price > 0 then
        local charged = lib.callback.await('fearx-crutchremover:chargeMoney', false, price)
        
        if not charged then
            exports['s6la_bridge']:notify(string.format(Config.Notifications.notEnoughMoney, price), 'error')
            return
        end
    end

    RemoveCrutch()
    exports['s6la_bridge']:notify(Config.Notifications.success .. (price > 0 and ' (-$' .. price .. ')' or ''), 'success')
end

-- edited by solph: original script had no support for anything but ox_target, which was useless for qb-core as they stopped support for that. now it actually works with all target systems and has proper error handling
local function AddNPCTarget(npc, index)
    if not DoesEntityExist(npc) then
        return
    end
    
    target_system = GetTargetSystem()
    
    if not target_system then
        return
    end
    
    local label_text = Config.ChargeMoney and ('Physical Therapy ($' .. Config.RemovalPrice .. ')') or 'Physical Therapy'
    
    if target_system == 'qb-target' then
        local success, err = pcall(function()
            exports['qb-target']:AddTargetEntity(npc, {
                options = {
                    {
                        type = 'client',
                        icon = 'fas fa-crutch',
                        label = label_text,
                        action = function()
                            if DoesEntityExist(npc) then
                                AttemptCrutchRemoval(npc)
                            end
                        end
                    }
                },
                distance = 2.0
            })
        end)
        if not success then
            print('^1[FearX-NpcCrutchRemover]^7 Error adding qb-target: ' .. tostring(err))
        end
    elseif target_system == 'ox_target' then
        local success, err = pcall(function()
            exports.ox_target:addLocalEntity(npc, {
                {
                    name = 'remove_crutch_' .. index,
                    icon = 'fas fa-crutch',
                    label = label_text,
                    onSelect = function(data)
                        if DoesEntityExist(data.entity) then
                            AttemptCrutchRemoval(data.entity)
                        end
                    end
                }
            })
        end)
        if not success then
            print('^1[FearX-NpcCrutchRemover]^7 Error adding ox_target: ' .. tostring(err))
        end
    elseif target_system == 'qtarget' then
        local success, err = pcall(function()
            exports['qtarget']:AddTargetEntity(npc, {
                options = {
                    {
                        type = 'client',
                        icon = 'fas fa-crutch',
                        label = label_text,
                        action = function()
                            if DoesEntityExist(npc) then
                                AttemptCrutchRemoval(npc)
                            end
                        end
                    }
                },
                distance = 2.0
            })
        end)
        if not success then
            print('^1[FearX-NpcCrutchRemover]^7 Error adding qtarget: ' .. tostring(err))
        end
    end
end

-- edited by solph: added delay because original script tried to add targets before NPCs even existed, causing errors everywhere
CreateThread(function()
    Wait(1000)
    CreateLocationBlips()
    SpawnNPCs()
    
    Wait(500)
    
    for i, npc in ipairs(spawnedNPCs) do
        if DoesEntityExist(npc) then
            AddNPCTarget(npc, i)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    RemoveLocationBlips()
    DeleteNPCs()
end)
