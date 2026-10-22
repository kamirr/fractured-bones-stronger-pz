local callbacks = {}
local chatCallbacks = {}
Events = {
	OnPlayerUpdate = {
		Add = function(callback)
			table.insert(callbacks, callback)
		end,
	},
	OnAddMessage = {
		Add = function(callback)
			table.insert(chatCallbacks, callback)
		end,
	},
}

local roll = 0
ZombRand = function()
	return roll
end
isClient = function()
	return false
end
SandboxVars = { FracturedBonesStronger = { PreventionChance = 50, EnableTestCommands = false } }

dofile("Contents/mods/FracturedBonesStronger/media/lua/shared/FractureProtection.lua")
assert(#callbacks == 1, "expected one player update callback")

local function newPlayer()
	local part = { fractureTime = 0, index = 3 }
	function part:getIndex()
		return self.index
	end
	function part:getType()
		return { name = function() return "ForeArm_L" end }
	end
	function part:getFractureTime()
		return self.fractureTime
	end
	function part:setFractureTime(value)
		self.fractureTime = value
	end

	local parts = { part }
	function parts:size()
		return #self
	end
	function parts:get(index)
		return self[index + 1]
	end

	local playerData = {}
	local bodyDamage = { getBodyParts = function() return parts end }
	local player = {
		getBodyDamage = function() return bodyDamage end,
		getModData = function() return playerData end,
		getUsername = function() return "Tester" end,
		setHaloNote = function() end,
	}
	return player, part, playerData
end

local function update(player)
	callbacks[1](player)
end

local player, part, data = newPlayer()

-- The first fracture is recorded, then the natural healing transition unlocks prevention.
part.fractureTime = 10
update(player)
assert(part.fractureTime == 10, "the first fracture must not be prevented")
part.fractureTime = 0
update(player)
assert(data.FracturedBonesStronger[3].healed, "healed history should be saved per body part")

-- The default 50% chance prevents a roll of 49, but not a roll of 50.
part.fractureTime = 10
roll = 49
update(player)
assert(part.fractureTime == 0, "a successful prevention roll should clear the new fracture")
update(player)
part.fractureTime = 10
roll = 50
update(player)
assert(part.fractureTime == 10, "the default chance should not prevent a roll equal to 50")

-- Healing another fracture does not raise the prevention chance.
part.fractureTime = 0
update(player)
part.fractureTime = 10
roll = 50
update(player)
assert(part.fractureTime == 10, "repeated healed fractures must not stack")

SandboxVars.FracturedBonesStronger.PreventionChance = 100
part.fractureTime = 0
update(player)
part.fractureTime = 10
roll = 99
update(player)
assert(part.fractureTime == 0, "100% should prevent every eligible fracture")

SandboxVars.FracturedBonesStronger.PreventionChance = 0
part.fractureTime = 0
update(player)
part.fractureTime = 10
roll = 0
update(player)
assert(part.fractureTime == 10, "0% should never prevent a fracture")

local testPlayer, testPart, testData = newPlayer()
getPlayer = function() return testPlayer end
local function sendChatCommand(text)
	chatCallbacks[1]({
		getAuthor = function() return "Tester" end,
		getText = function() return text end,
	})
end

sendChatCommand("/fbs fracture")
assert(testPart.fractureTime == 0, "test commands must be inert when their sandbox option is off")
SandboxVars.FracturedBonesStronger.EnableTestCommands = true
SandboxVars.FracturedBonesStronger.PreventionChance = 100
sendChatCommand("/fbs reset ForeArm_L")
sendChatCommand("/fbs fracture ForeArm_L")
assert(testPart.fractureTime > 0, "fracture command should force the initial fracture")
sendChatCommand("/fbs heal ForeArm_L")
assert(testPart.fractureTime == 0, "heal command should clear the fracture")
assert(testData.FracturedBonesStronger[3].healed, "heal command should record the healed transition")
sendChatCommand("/fbs fracture ForeArm_L")
assert(testPart.fractureTime == 0, "a second fracture command should use the real prevention path")
sendChatCommand("/fbs test ForeArm_L")
assert(testPart.fractureTime == 0, "test command should perform the full fracture/heal/re-fracture lifecycle")

print("fracture prevention behavior: OK")
