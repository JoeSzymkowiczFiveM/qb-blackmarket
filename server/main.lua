local QBCore = exports['qb-core']:GetCoreObject()

MongoDB.ready(function()
    MongoDB.Sync.delete({collection = 'blackmarket', query = { ["items"] = { ["$exists"] = false } } })
end)

local Locations = {
    vector4(681.1276245, -2700.66381, 7.17168951, 278.382019),
    vector4(-1521.27893, -575.978027, 33.35451889, 38.16072463),
}

local Stuff = {
    ['nitrous'] = {
        cost = 3.0,
        label = "Nitrous Oxide",
    },
}

local chosenLoc = nil

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        exports['ps-peds']:removePed(resourceName.."_1", 'ghost')
    end
end)

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    chosenLoc = math.random(1, #Locations)
    local ped = {
        model = "cs_joeminuteman",
        coords = vector3(Locations[chosenLoc].x, Locations[chosenLoc].y, Locations[chosenLoc].z),
        heading = Locations[chosenLoc].w,
        gender = "male",
        scenario = "WORLD_HUMAN_CLIPBOARD",
        isRendered = false,
        ped = nil,
        options = {
        {
            event = "qb-blackmarket:client:PickupBlackMarketStuff",
            icon = "fas fa-box-open",
            label = "Pickup Packages",
        },
    },
        optionsDistance = 3.5
    }
    exports['ps-peds']:addPed(resourceName.."_1", ped)
end)

RegisterServerEvent('qb-blackmarket:server:PickupStuff', function(securityToken)
    if not exports['salty_tokenizer']:secureServerEvent(GetCurrentResourceName(), source, securityToken) then
		return false
	end

    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid

    local coords = vector3(Locations[chosenLoc].x, Locations[chosenLoc].y, Locations[chosenLoc].z)
    local sourcePed = GetPlayerPed(src)
	local sourceCoords = GetEntityCoords(sourcePed)

    if #(sourceCoords - coords) < 2 then
        --local result = MySQL.query.await('SELECT * FROM blackmarket WHERE citizenid = ?', {citizenid})
        local result = MongoDB.Sync.findOneAndUpdate({collection = 'blackmarket', query = { citizenid = citizenid }, 
            update = { 
                ["$unset"] = { ["items"] = '' },
            },
            options = {
                upsert = true,
                returnDocument = 'before'
            }
        })
        if result['value'] ~= nil then
            for _, v in pairs(result['value']['items']) do
                Player.Functions.AddItem(v.item, 1)
                local item = QBCore.Functions.GetSharedItems(v.item)
                Wait(500)
            end
            --MySQL.query('DELETE FROM blackmarket WHERE citizenid = ?', {citizenid})
            TriggerClientEvent('QBCore:Notify', src, "Packages picked up..", "success")
        else
            TriggerClientEvent('QBCore:Notify', src, "Nothing here for you..", "error")
        end
        --exports['ps-peds']:modifyAnim('blackmarket_ped', {dict = "missminuteman_1ig_2", anim = "handsup_base"})
        --exports['ps-peds']:fleePed('blackmarket_ped')
    end
end)

QBCore.Functions.CreateCallback('qb-blackmarket:server:GetList', function(source, cb)
    local itemTable = Stuff
    cb(itemTable)
end)

QBCore.Functions.CreateCallback('qb-blackmarket:server:BuyStuff', function(source, cb, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.Functions.RemoveMoney("crypto", Stuff[item].cost, "blackmarket-item-bought") then
        TriggerClientEvent('qb-blackmarket:client:sendPickupMail', src, vector3(Locations[chosenLoc].x, Locations[chosenLoc].y, Locations[chosenLoc].z))
        --MySQL.insert('INSERT INTO blackmarket (citizenid, item) VALUES (?, ?) ', {Player.PlayerData.citizenid, item})
        MongoDB.Sync.findOneAndUpdate({collection = 'blackmarket', query = { citizenid = Player.PlayerData.citizenid }, 
            update = { 
                ["$setOnInsert"] = {
                    citizenid = Player.PlayerData.citizenid,
                },
                ["$push"] = { ["items"] = {date = os.date('%Y-%m-%d %H:%M:%S'), item = item} } }, 
            options = { upsert = true } }
        )
        cb(true)
    else
        TriggerClientEvent('QBCore:Notify', src, "You don\'t have enough Qbits for that..", "error")
    end
end)