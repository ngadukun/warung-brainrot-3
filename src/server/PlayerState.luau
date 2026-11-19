-- PlayerState.luau — the single store of game state.
-- Player data, the live brainrot registry, base plots and the world-event
-- state all live here; every other service reads and writes through this
-- module so there is exactly one place where state changes.

local Config = require(script.Parent:WaitForChild("Config"))

local PlayerState = {}

-- [Player] = { cash, totalEarned, incomePerSecond, rebirths, multiplier,
--              plotIndex, slotCount, slots = { [slotIndex] = record },
--              lockUntil, lockCooldownUntil, carrying }
PlayerState.players = {}

-- Set of every live brainrot record (on the belt, walking, on a base, carried).
-- record = { model, def, mutation, income, price, state, owner, slot, beltZ }
PlayerState.brainrots = {}

-- [plotIndex] = plot record built by WorldBuilder and adopted by BaseService:
-- { index, name, color, center, pads = { { disc, ring, position } }, owner,
--   incomeLabel }
PlayerState.plots = {}

-- World event state. nextKind/activeKind are "Krupuk" or "Disco".
PlayerState.event = {
	activeKind = nil,
	endsAt = 0,
	nextAt = os.clock() + Config.EventInterval,
	nextKind = "Krupuk",
	incomeFactor = 1,
}

function PlayerState.now(): number
	return os.clock()
end

function PlayerState.registerPlayer(player: Player)
	local data = {
		cash = Config.StartCash,
		totalEarned = 0,
		incomePerSecond = 0,
		rebirths = 0,
		multiplier = 1,
		plotIndex = nil,
		slotCount = Config.StartSlots,
		slots = {},
		lockUntil = 0,
		lockCooldownUntil = 0,
		carrying = nil,
	}
	PlayerState.players[player] = data
	return data
end

function PlayerState.removePlayer(player: Player)
	PlayerState.players[player] = nil
end

function PlayerState.get(player: Player)
	return PlayerState.players[player]
end

function PlayerState.addBrainrot(record)
	PlayerState.brainrots[record] = true
end

function PlayerState.removeBrainrot(record)
	PlayerState.brainrots[record] = nil
end

-- Number of base slots currently holding a brainrot for this player.
function PlayerState.ownedCount(data): number
	local count = 0
	for _ in pairs(data.slots) do
		count += 1
	end
	return count
end

-- How many more brainrots fit on the player's base right now. A brainrot the
-- player is carrying home already promises one slot, so it counts as used.
function PlayerState.freeSlotCount(data): number
	local used = PlayerState.ownedCount(data)
	if data.carrying then
		used += 1
	end
	return data.slotCount - used
end

-- The lowest-numbered empty slot on the player's base, or nil when full.
function PlayerState.firstFreeSlot(data): number?
	for slotIndex = 1, data.slotCount do
		if data.slots[slotIndex] == nil then
			return slotIndex
		end
	end
	return nil
end

-- Is this player's base locked right now?
function PlayerState.isLocked(data): boolean
	return data ~= nil and PlayerState.now() < data.lockUntil
end

-- The price of the player's next base slot, or nil when already at the max.
function PlayerState.nextSlotPrice(data): number?
	if data.slotCount >= Config.MaxSlots then
		return nil
	end
	return Config.SlotBasePrice * 2 ^ (data.slotCount - Config.StartSlots)
end

return PlayerState
