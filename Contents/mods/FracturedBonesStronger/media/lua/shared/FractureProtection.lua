local DEFAULT_PREVENTION_CHANCE = 50
local PLAYER_DATA_KEY = "FracturedBonesStronger"

local function getPreventionChance()
	local settings = SandboxVars and SandboxVars.FracturedBonesStronger
	local chance = settings and tonumber(settings.PreventionChance) or DEFAULT_PREVENTION_CHANCE
	return math.max(0, math.min(100, math.floor(chance)))
end

local function onPlayerUpdate(player)
	if not player then
		return
	end

	-- In multiplayer, let the server make and replicate the prevention decision.
	if isClient and isClient() then
		return
	end

	local bodyDamage = player:getBodyDamage()
	if not bodyDamage then
		return
	end

	local playerData = player:getModData()
	local fractureHistory = playerData[PLAYER_DATA_KEY]
	if type(fractureHistory) ~= "table" then
		fractureHistory = {}
		playerData[PLAYER_DATA_KEY] = fractureHistory
	end

	local chance = getPreventionChance()
	local bodyParts = bodyDamage:getBodyParts()
	if not bodyParts then
		return
	end

	for index = 0, bodyParts:size() - 1 do
		local bodyPart = bodyParts:get(index)
		local partIndex = bodyPart:getIndex()
		local history = fractureHistory[partIndex]
		if type(history) ~= "table" then
			history = nil
			fractureHistory[partIndex] = nil
		end

		if bodyPart:getFractureTime() > 0 then
			if not history then
				history = { healed = false, active = false }
				fractureHistory[partIndex] = history
			end

			-- A single healed flag records history, so repeated fractures never raise the chance.
			if history.healed and not history.active and chance > 0 and ZombRand(100) < chance then
				bodyPart:setFractureTime(0)
			end
			history.active = true
		elseif history and history.active then
			history.active = false
			history.healed = true
		end
	end
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)
