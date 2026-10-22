local DEFAULT_PREVENTION_CHANCE = 50
local PLAYER_DATA_KEY = "FracturedBonesStronger"
local TEST_COMMAND_MODULE = "FracturedBonesStronger"
local DEFAULT_TEST_PART = "forearml"

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

local function areTestCommandsEnabled()
	local settings = SandboxVars and SandboxVars.FracturedBonesStronger
	return settings and settings.EnableTestCommands == true
end

local function normalizePartName(partName)
	return string.lower(tostring(partName or "")):gsub("[^%w]", "")
end

local PART_ALIASES = {
	leftforearm = "forearml",
	rightforearm = "forearmr",
	forearmleft = "forearml",
	forearmright = "forearmr",
	leftshin = "shinl",
	rightshin = "shinr",
	shinleft = "shinl",
	shinright = "shinr",
	leftthigh = "thighl",
	rightthigh = "thighr",
	thighleft = "thighl",
	thighright = "thighr",
	upperlegl = "thighl",
	upperlegr = "thighr",
	lowerlegl = "shinl",
	lowerlegr = "shinr",
}

local function getPartTypeName(bodyPart)
	local partType = bodyPart:getType()
	if not partType then
		return ""
	end

	local ok, name = pcall(function()
		return partType:name()
	end)
	if ok and name then
		return normalizePartName(name)
	end
	return normalizePartName(partType)
end

local function findBodyPart(player, requestedName)
	local bodyDamage = player:getBodyDamage()
	local bodyParts = bodyDamage and bodyDamage:getBodyParts()
	if not bodyParts then
		return nil
	end

	local targetName = normalizePartName(requestedName or DEFAULT_TEST_PART)
	targetName = PART_ALIASES[targetName] or targetName
	for index = 0, bodyParts:size() - 1 do
		local bodyPart = bodyParts:get(index)
		local partTypeName = getPartTypeName(bodyPart)
		partTypeName = PART_ALIASES[partTypeName] or partTypeName
		if partTypeName == targetName then
			return bodyPart
		end
	end
	return nil
end

local function getTestHistory(player, partIndex, create)
	local playerData = player:getModData()
	local history = playerData[PLAYER_DATA_KEY]
	if type(history) ~= "table" then
		if not create then
			return nil
		end
		history = {}
		playerData[PLAYER_DATA_KEY] = history
	end
	return history[partIndex], history
end

local function notifyTestCommand(player, message)
	print("[FracturedBonesStronger] " .. message)
	if player and player.setHaloNote then
		player:setHaloNote(message, 255, 255, 255, 3.0)
	end
end

local function isAuthorizedTestPlayer(player)
	if isServer and isServer() then
		if not player or not player.getAccessLevel then
			return false
		end
		local accessLevel = player:getAccessLevel()
		return type(accessLevel) == "string" and string.lower(accessLevel) == "admin"
	end
	return true
end

local function handleTestCommand(player, action, requestedPart)
	if not areTestCommandsEnabled() then
		return "Test commands are disabled. Enable Fractured Bones Stronger test commands in Sandbox Options."
	end
	if not player then
		return "No player was found for this command."
	end
	if not isAuthorizedTestPlayer(player) then
		return "Only an admin can use these test commands."
	end

	action = string.lower(action or "help")
	if action == "help" then
		return "Use /fbs test|fracture|heal|status|reset [body-part]. Default body-part: ForeArm_L."
	end

	local bodyPart = findBodyPart(player, requestedPart)
	if not bodyPart then
		return "Unknown body-part. Try ForeArm_L, ForeArm_R, Shin_L/LowerLeg_L, Shin_R/LowerLeg_R, Thigh_L/UpperLeg_L, or Thigh_R/UpperLeg_R."
	end

	local partIndex = bodyPart:getIndex()
	local history = getTestHistory(player, partIndex, false)
	if action == "status" then
		onPlayerUpdate(player)
		history = getTestHistory(player, partIndex, false)
		local healed = history and history.healed and "yes" or "no"
		return string.format("%s: fractureTime=%s, healed-history=%s.", requestedPart or "ForeArm_L", tostring(bodyPart:getFractureTime()), healed)
	elseif action == "reset" then
		local _, allHistory = getTestHistory(player, partIndex, true)
		allHistory[partIndex] = nil
		bodyPart:setFractureTime(0)
		onPlayerUpdate(player)
		return "Reset " .. (requestedPart or "ForeArm_L") .. "; its next fracture will be treated as the first."
	elseif action == "fracture" then
		bodyPart:setFractureTime(10)
		onPlayerUpdate(player)
		if bodyPart:getFractureTime() == 0 then
			return (requestedPart or "ForeArm_L") .. " fracture was prevented."
		end
		return "Forced a fracture on " .. (requestedPart or "ForeArm_L") .. ". Use /fbs heal, then /fbs fracture to test prevention."
	elseif action == "heal" then
		bodyPart:setFractureTime(0)
		onPlayerUpdate(player)
		return "Cleared the fracture on " .. (requestedPart or "ForeArm_L") .. "; healed history is now recorded."
	elseif action == "test" then
		local _, allHistory = getTestHistory(player, partIndex, true)
		allHistory[partIndex] = nil
		bodyPart:setFractureTime(0)
		bodyPart:setFractureTime(10)
		onPlayerUpdate(player) -- Record a first fracture.
		bodyPart:setFractureTime(0)
		onPlayerUpdate(player) -- Record that the first fracture healed.
		bodyPart:setFractureTime(10)
		onPlayerUpdate(player) -- Attempt a second fracture through the real prevention path.
		if bodyPart:getFractureTime() == 0 then
			return "Test complete: the second fracture was prevented."
		end
		return "Test complete: the second fracture was allowed. Run again to roll again."
	end

	return "Unknown action. Use /fbs help."
end

local function parseTestCommand(text)
	local commandText = text and text:match("^%s*/fbs%s*(.-)%s*$")
	if commandText == nil then
		return nil
	end
	local action, partName = commandText:match("^(%S+)%s*(.-)$")
	return string.lower(action or "help"), partName ~= "" and partName or nil
end

local function onAddChatMessage(message)
	if not areTestCommandsEnabled() or not message then
		return
	end

	local player = getPlayer and getPlayer()
	if not player then
		return
	end
	local author = message:getAuthor()
	if author and author ~= player:getUsername() then
		return
	end

	local action, partName = parseTestCommand(message:getText())
	if not action then
		return
	end

	if isClient and isClient() then
		sendClientCommand(player, TEST_COMMAND_MODULE, "testCommand", { action = action, part = partName })
	else
		notifyTestCommand(player, handleTestCommand(player, action, partName))
	end
end

local function onTestClientCommand(module, command, player, args)
	if module ~= TEST_COMMAND_MODULE or command ~= "testCommand" then
		return
	end
	local message = handleTestCommand(player, args and args.action, args and args.part)
	if sendServerCommand then
		sendServerCommand(player, TEST_COMMAND_MODULE, "testResult", { message = message })
	end
end

local function onTestServerCommand(module, command, args)
	if module ~= TEST_COMMAND_MODULE or command ~= "testResult" then
		return
	end
	notifyTestCommand(getPlayer and getPlayer(), args and args.message or "Test command completed.")
end

if Events.OnAddMessage then
	Events.OnAddMessage.Add(onAddChatMessage)
end
if Events.OnClientCommand then
	Events.OnClientCommand.Add(onTestClientCommand)
end
if Events.OnServerCommand then
	Events.OnServerCommand.Add(onTestServerCommand)
end
