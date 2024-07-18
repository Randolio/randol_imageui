local Locations = {}
local menuZones = {}
local findingSpot = false

local function rotationToDirection(rotation)
    local adjustedRotation = vec3((math.pi / 180) * rotation.x, (math.pi / 180) * rotation.y, (math.pi / 180) * rotation.z)
    local direction = vec3(-math.sin(adjustedRotation.z) * math.cos(adjustedRotation.x), math.cos(adjustedRotation.z) * math.cos(adjustedRotation.x), math.sin(adjustedRotation.x))
    return direction
end

local function raycastFromCamera(distance)
    local cameraRotation = GetGameplayCamRot(2)
    local cameraCoord = GetGameplayCamCoord()
    local direction = rotationToDirection(cameraRotation)
    local destination = vec3(cameraCoord.x + direction.x * distance, cameraCoord.y + direction.y * distance, cameraCoord.z + direction.z * distance)

    local rayHandle = StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, -1, 1)
    local _, hit, endCoords, _, _ = GetShapeTestResult(rayHandle)

    return hit, endCoords
end

local function findCoords()
    local hasCoords
    local coords
    local heightOffset = 0.0
    findingSpot = true

    lib.showTextUI('**ENTER** - Copy Coordinates  \n**BACKSPACE** - Cancel  \n**SCROLL UP** - Raise Height  \n**SCROLL DOWN** - Lower Height', { position = 'left-center' })

    while findingSpot do
        Wait(0)
        local hit, markerPosition = raycastFromCamera(15.0)

        if hit then
            coords = markerPosition
        end

        if coords then
            DrawMarker(28, coords.x, coords.y, coords.z + heightOffset, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.7, 230, 7, 70, 80, false, false, 2, nil, nil, false)
        end

        if IsControlJustReleased(0, 191) then
            if coords then
                hasCoords = vec3(coords.x, coords.y, coords.z + heightOffset)
                findingSpot = false
            end
        elseif IsControlJustReleased(0, 177) then
            findingSpot = false
        elseif IsControlJustReleased(0, 15) then
            heightOffset += 0.1
        elseif IsControlJustReleased(0, 14) then
            heightOffset -= 0.1
        end
    end

    lib.hideTextUI()
    return hasCoords
end

local function showImage(link)
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'showImage', image = link })
end
exports('showImage', showImage)

RegisterNUICallback('closeImage', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

function toggleZones(bool)
    if bool then
        for zone, data in pairs(Locations) do
            exports['qb-target']:AddCircleZone(zone, vec3(data.coords.x, data.coords.y, data.coords.z), 0.7, {
                name = zone,
                useZ = true,
                debugPoly = false,
            }, {
                options =
                {
                    {
                        icon = 'fa-solid fa-hand',
                        label = data.label,
                        action = function()
                            showImage(data.link)
                        end,
                    },
                },
                distance = 2.5
            })
            menuZones[#menuZones+1] = zone
        end
    else
        table.wipe(Locations)
        for i = 1, #menuZones do
            exports['qb-target']:RemoveZone(menuZones[i])
        end
        table.wipe(menuZones)
    end
end

RegisterNetEvent('randol_imageui:client:createNew', function()
    if GetInvokingResource() or findingSpot then return end
    local hasCoords = findCoords()
    if not hasCoords then return end

    local finalCoords = vec3(hasCoords.x, hasCoords.y, hasCoords.z)
    local response = lib.inputDialog('Create Menu', {
        {
            type = 'input',
            label = 'Target Label',
            required = true,
            icon = 'fa-solid fa-pen',
            placeholder = 'Example: Pearls Menu', 
        },
        {
            type = 'input',
            label = 'Image Link',
            required = true,
            icon = 'fa-solid fa-link',
            placeholder = 'Example: https://r2.fivemanage.com/pub/CUM.png',
            description = 'Upload your menu image to a valid image host.', 
        },
    })

    if not response then return end

    if not (string.find(response[2], '.png') or string.find(response[2], '.jpg')) then
        return DoNotification('Must use a link ending in .png or .jpg.', 'error')
    end
    
    TriggerServerEvent('randol_imageui:server:createMenu', response[1], response[2], finalCoords)
end)

RegisterNetEvent('randol_imageui:client:viewMenus', function(data)
    if GetInvokingResource() then return end
    local job = GetJobLabel()
    local options = {}
    for _, zone in ipairs(data) do
        options[#options + 1] = {
            title = zone.label,
            description = ('%s | %s'):format(tostring(zone.coords), tostring(zone.link)),
            icon = 'link',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = 'Delete Menu',
                    content = '**Are you sure you want to delete the current menu location?**',
                    centered = true,
                    cancel = true,
                    labels = {
                        cancel = 'No',
                        confirm = 'Yes'
                    }
                })
                if alert == 'cancel' then return end
                TriggerServerEvent('randol_imageui:server:deleteMenu', zone)
            end,
        }
    end
    lib.registerContext({ id = 'business_view_menus', title = ('Created Menus: %s'):format(job), options = options })
    lib.showContext('business_view_menus')
end)

RegisterNetEvent('randol_imageui:client:setLocations', function(locs)
    if GetInvokingResource() or not hasPlyLoaded() then return end
    Locations = locs
    Wait(500)
    toggleZones(true)
end)

RegisterNetEvent('randol_imageui:client:addZone', function(zone)
    if GetInvokingResource() or not hasPlyLoaded() then return end

    exports['qb-target']:AddCircleZone(zone.id, vec3(zone.coords.x, zone.coords.y, zone.coords.z), 0.7, {
        name = zone.id,
        useZ = true,
        debugPoly = false,
    }, {
        options = {
            {
                icon = 'fa-solid fa-hand',
                label = zone.label,
                action = function()
                    showImage(zone.link)
                end,
            },
        },
        distance = 2.5
    })

    menuZones[#menuZones+1] = zone.id
    Locations[zone.id] = zone
end)

RegisterNetEvent('randol_imageui:client:removeZone', function(zoneId)
    if GetInvokingResource() or not hasPlyLoaded() then return end

    for i = 1, #menuZones do
        if menuZones[i] == zoneId then
            exports['qb-target']:RemoveZone(zoneId)
            table.remove(menuZones, i)
            break
        end
    end

    if Locations[zoneId] then
        Locations[zoneId] = nil
    end
end)
