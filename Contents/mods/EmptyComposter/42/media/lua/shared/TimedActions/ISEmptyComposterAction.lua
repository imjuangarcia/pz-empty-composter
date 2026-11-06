-- Empty Composter (Build 42)
--
-- Timed action that throws out whatever compost is left in a composter.
-- Modeled on the vanilla rain barrel "Empty" action (ISEmptyRainBarrelAction),
-- which lives in shared/TimedActions with the same perform/complete split:
-- in multiplayer the server runs complete(); in single player both run.

require "TimedActions/ISBaseTimedAction"

ISEmptyComposterAction = ISBaseTimedAction:derive("ISEmptyComposterAction")

-- Setting the compost to 0 is idempotent, so it is safe if both
-- perform() and complete() end up running it.
local function emptyComposter(compost)
    if not compost then return end
    compost:setCompost(0)
    compost:updateSprite()
    compost:syncCompost()
end

function ISEmptyComposterAction:isValid()
    return self.compost ~= nil
        and self.compost:getObjectIndex() ~= -1
        and self.compost:getCompost() > 0
end

function ISEmptyComposterAction:waitToStart()
    self.character:faceThisObject(self.compost)
    return self.character:shouldBeTurning()
end

function ISEmptyComposterAction:update()
    self.character:faceThisObject(self.compost)
end

function ISEmptyComposterAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
end

function ISEmptyComposterAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISEmptyComposterAction:perform()
    -- Single player (not a multiplayer client): apply the change here as well,
    -- in case complete() is not reached on this side.
    if not isClient() then
        emptyComposter(self.compost)
    end
    ISBaseTimedAction.perform(self)
end

-- Runs on the server in multiplayer (and locally in single player).
function ISEmptyComposterAction:complete()
    emptyComposter(self.compost)
    return true
end

function ISEmptyComposterAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 80
end

function ISEmptyComposterAction:new(character, compost)
    local o = ISBaseTimedAction.new(self, character)
    o.compost = compost
    o.maxTime = o:getDuration()
    return o
end
