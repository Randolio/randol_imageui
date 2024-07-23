local Server = lib.load('sv_config')
local Locations = {}

local function sendLog(title, message)
    if not Server.Webhook or Server.Webhook == '' then
        return print('^5Your discord webhook is empty, please set a webhook if you want to use logging.^7')
    end
    
    local embed = { { ['title'] = title, ['description'] = message, } }
    PerformHttpRequest(Server.Webhook, function(err, text, headers) end, 'POST', json.encode({ username = 'Business Logs', embeds = embed }), { ['Content-Type'] = 'application/json' })
end

local function generateZoneId()
    local gen
    repeat
        gen = 'zoneName_' .. math.random(111111, 999999)
    until not Locations[gen]

    return gen
end

local function getLocations()
    local result = MySQL.query.await('SELECT * from business_menus')
    if result and result[1] then
        for _, menu in pairs(result) do
            local location = json.decode(menu.coords)
            Locations[menu.zone] = { label = menu.label, coords = vec3(location.x, location.y, location.z), link = menu.link, job = menu.job, id = menu.zone }
        end
        TriggerClientEvent('randol_imageui:client:setLocations', -1, Locations)
    end
end

local function getJobMenus(job)
    local data = {}
    for id, info in pairs(Locations) do
        if job == info.job then
            data[#data+1] = { label = info.label, coords = info.coords, link = info.link, job = info.job, id = id, }
        end
    end
    return data
end

RegisterNetEvent('randol_imageui:server:createMenu', function(label, link, loc)
    local src = source
    local player = GetPlayer(src)
    local job = GetPlayerJob(player)
    if Server.BlacklistedJobs[job] then return end

    local coords = vec3(loc.x, loc.y, loc.z)
    local id = generateZoneId()

    local success = MySQL.insert.await('INSERT INTO business_menus (label, coords, link, job, zone) VALUES (?, ?, ?, ?, ?)', {label, json.encode(coords), link, job, id})
    if not success then return end

    Locations[id] = {label = label, coords = coords, link = link, job = job, id = id }

    DoNotification(src, 'New Menu Created: '..label..'.', 'success')
    TriggerClientEvent('randol_imageui:client:addZone', -1, Locations[id])
    sendLog('Menu Zone Created', ('**%s [%s]**\nLocation: `%s`\nBusiness: `%s`\nImage: `%s`'):format(GetPlayerName(src), src, tostring(coords), job, link))
end)

RegisterNetEvent('randol_imageui:server:deleteMenu', function(data)
    local src = source
    local player = GetPlayer(src)
    local job = GetPlayerJob(player)
    
    if Server.BlacklistedJobs[job] then return end

    local success = MySQL.update.await('DELETE FROM business_menus WHERE zone = ?', {data.id})
    if not success then return end
    
    Locations[data.id] = nil
    DoNotification(src, ('You removed business menu: %s'):format(data.label), 'success')
    TriggerClientEvent('randol_imageui:client:removeZone', -1, data.id)
    sendLog('Menu Zone Deleted', ('**%s [%s]**\nLocation: `%s`\nBusiness: `%s`'):format(GetPlayerName(src), src, tostring(data.coords), job))
end)

lib.addCommand('newmenu', { help = 'Create a new menu location.'}, function(source)
    local player = GetPlayer(source)
    local job = GetPlayerJob(player)
    if Server.BlacklistedJobs[job] then return end
    TriggerClientEvent('randol_imageui:client:createNew', source)
end)

lib.addCommand('viewmenus', { help = 'Manage current job menus.'}, function(source)
    local player = GetPlayer(source)
    local job = GetPlayerJob(player)
    if Server.BlacklistedJobs[job] then return end
    local data = getJobMenus(job)
    TriggerClientEvent('randol_imageui:client:viewMenus', source, data)
end)

function OnPlayerLoaded(source)
    SetTimeout(2000, function()
        TriggerClientEvent('randol_imageui:client:setLocations', source, Locations)
    end)
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    MySQL.query([=[
        CREATE TABLE IF NOT EXISTS `business_menus` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `label` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
            `coords` TEXT NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
            `link` VARCHAR(255) NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
            `job` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
            `zone` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb3_general_ci',
            PRIMARY KEY (`id`)
        );
    ]=])
    SetTimeout(2000, getLocations)
end)
