-- Empty Composter (Build 42)
--
-- Adds "Empty Composter" to the right-click menu of any composter that still
-- holds compost, the same way a rain barrel can be emptied. A sack only takes
-- compost 2.5 at a time, so a smaller leftover can't be removed, and a
-- composter that still holds compost can't be picked up. This clears it.
--
-- Where the option goes: since 42.20 the Gardening submenu is built by the game's
-- Java code, which calls ISWorldObjectContextMenu.handleCompost(test, context,
-- ...) with that submenu as `context` to add "Get Compost". We wrap that
-- function and add our option to the same submenu, right after the vanilla
-- compost options. If the wrapper doesn't run for a menu (a build that makes
-- the menu differently), the option goes at the end of the main menu instead,
-- so it's never missing and never shown twice.

require "ISUI/ISWorldObjectContextMenu"

EmptyComposter = EmptyComposter or {}

-- A sack takes compost this much at a time; anything below it is stuck.
EmptyComposter.SACK_MINIMUM = 2.5

-- True once the option went into the Gardening submenu of the menu being built.
EmptyComposter.addedToGardening = false

local function findComposter(worldobjects)
    for _, obj in ipairs(worldobjects) do
        local square = obj:getSquare()
        if square then
            local objects = square:getObjects()
            for i = 0, objects:size() - 1 do
                local o = objects:get(i)
                if instanceof(o, "IsoCompost") then
                    return o
                end
            end
        end
    end
    return nil
end

-- Rounds to one decimal and adds the percent sign, e.g. "0.8%". The sign goes
-- in the argument, not in the translation text: since 42.20 translations are
-- Java format strings, and a bare "%" there breaks the substitution.
local function formatAmount(amount)
    return tostring(math.floor(amount * 10 + 0.5) / 10) .. "%"
end

local function onEmptyComposter(compost, playerObj)
    if not compost or compost:getObjectIndex() == -1 then return end
    if luautils.walkAdj(playerObj, compost:getSquare()) then
        ISTimedActionQueue.add(ISEmptyComposterAction:new(playerObj, compost))
    end
end

-- Adds the option to `context` if the composter holds any compost.
local function addEmptyOption(context, compost, playerObj)
    if not context or not compost or not playerObj then return false end
    local amount = compost:getCompost()
    if amount <= 0 then return false end
    local label = getText("ContextMenu_EmptyComposter", formatAmount(amount))
    context:addGetUpOption(label, compost, onEmptyComposter, playerObj)
    return true
end

-- Gardening submenu: run vanilla first so our option lands after "Get Compost".
local vanillaHandleCompost = ISWorldObjectContextMenu and ISWorldObjectContextMenu.handleCompost
if vanillaHandleCompost then
    ISWorldObjectContextMenu.handleCompost = function(test, context, worldobjects, playerObj, playerInv, ...)
        local result = vanillaHandleCompost(test, context, worldobjects, playerObj, playerInv, ...)
        if not test then
            local fetch = ISWorldObjectContextMenu.fetchVars
            if addEmptyOption(context, fetch and fetch.compost, playerObj) then
                EmptyComposter.addedToGardening = true
            end
        end
        return result
    end
end

-- A new menu is being built: forget the previous one.
local function onPreFillWorldObjectContextMenu()
    EmptyComposter.addedToGardening = false
end

-- Fallback: end of the main menu, only if the Gardening submenu didn't get it.
local function onFillWorldObjectContextMenu(player, context, worldobjects, test)
    if test then return end
    local addedToGardening = EmptyComposter.addedToGardening
    EmptyComposter.addedToGardening = false
    if addedToGardening then return end

    local playerObj = getSpecificPlayer(player)
    if not playerObj or playerObj:getVehicle() then return end

    addEmptyOption(context, findComposter(worldobjects), playerObj)
end

if Events.OnPreFillWorldObjectContextMenu then
    Events.OnPreFillWorldObjectContextMenu.Add(onPreFillWorldObjectContextMenu)
end
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

-- Debug fallback, for when the menu option doesn't show up. Stand next to a
-- stuck composter and run this in the debug Lua console:
--   EmptyComposter.clearLeftovers()
-- It only touches adjacent composters holding less than a sack's minimum, so
-- it never throws away compost you could still take, and prints what it found.
function EmptyComposter.clearLeftovers()
    local playerObj = getPlayer()
    local sq = playerObj and playerObj:getCurrentSquare()
    if not sq then
        print("[EmptyComposter] no player square")
        return
    end
    local found = 0
    for dx = -1, 1 do
        for dy = -1, 1 do
            local s = getCell():getGridSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
            if s then
                local objects = s:getObjects()
                for i = 0, objects:size() - 1 do
                    local o = objects:get(i)
                    if instanceof(o, "IsoCompost") then
                        found = found + 1
                        local amount = o:getCompost()
                        print("[EmptyComposter] composter at " .. s:getX() .. "," .. s:getY() .. " holds " .. tostring(amount))
                        if amount > 0 and amount < EmptyComposter.SACK_MINIMUM then
                            o:setCompost(0)
                            o:updateSprite()
                            o:syncCompost()
                            print("[EmptyComposter] cleared")
                        end
                    end
                end
            end
        end
    end
    print("[EmptyComposter] composters found: " .. found)
end
