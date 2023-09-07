local QBCore = exports['qb-core']:GetCoreObject()

local chosenLoc = nil

RegisterNetEvent('qb-blackmarket:client:PickupBlackMarketStuff', function()
	TriggerServerEvent('qb-blackmarket:server:PickupStuff', securityToken)
end)

RegisterNetEvent('qb-blackmarket:client:sendPickupMail', function(location)
    chosenLoc = location
    local data = {
        subject = "SilQroad",
        message = "Your order has been processed. Use the button below to mark the pickup location.",
        button = {
            enabled = true,
            buttonEvent = "qb-blackmarket:client:setLocation",
            buttonData = ''
        }
    }
    TriggerEvent("qb-phone:client:AddDarkLogEntry", data)
    TriggerEvent('qb-phone:client:DarklogNotification', {
        message = "New DarkLog entry!",
    })
end)

RegisterNetEvent('qb-blackmarket:client:setLocation', function()
    SetNewWaypoint(chosenLoc.x, chosenLoc.y)
    QBCore.Functions.Notify('Pickup location has been set on your map.', 'success');
end)