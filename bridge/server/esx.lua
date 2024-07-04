if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports['es_extended']:getSharedObject()

function GetPlayer(id)
    return ESX.GetPlayerFromId(id)
end

function DoNotification(src, text, nType)
    TriggerClientEvent('esx:showNotification', src, text, nType)
end

function GetPlayerJob(xPlayer)
    return xPlayer.job.name
end

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    OnPlayerLoaded(playerId)
end)