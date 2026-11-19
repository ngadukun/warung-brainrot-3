-- EconomyService.luau — money: the one-second income tick, conveyor
-- purchases, and the state snapshots the HUD renders from.

local Config = require(script.Parent:WaitForChild("Config"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ConveyorService = require(script.Parent:WaitForChild("ConveyorService"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local StealService = require(script.Parent:WaitForChild("StealService"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local EconomyService = {}

local remotes = nil

local function toast(player: Player, message: string)
	if remotes then
		remotes.Toast:FireClient(player, message)
	end
end

local function characterRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

-- Everything the HUD needs, in one small table, pushed once a second.
function EconomyService.buildSnapshot(player: Player)
	local data = PlayerState.get(player)
	if not data then
		return nil
	end
	local now = PlayerState.now()
	local event = PlayerState.event
	return {
		cash = math.floor(data.cash),
		income = math.floor(data.incomePerSecond),
		multiplier = data.multiplier,
		rebirths = data.rebirths,
		slotCount = data.slotCount,
		ownedCount = PlayerState.ownedCount(data),
		nextSlotPrice = PlayerState.nextSlotPrice(data) or 0,
		canRebirth = data.totalEarned >= Config.RebirthThreshold,
		rebirthProgress = math.floor(data.totalEarned),
		lockLeft = math.max(0, math.ceil(data.lockUntil - now)),
		lockCooldownLeft = math.max(0, math.ceil(data.lockCooldownUntil - now)),
		carrying = data.carrying ~= nil,
		carryingName = data.carrying and BrainrotFactory.displayName(data.carrying) or nil,
		eventActive = event.activeKind and Config.EventDisplayNames[event.activeKind] or nil,
		eventEndsIn = event.activeKind and math.max(0, math.ceil(event.endsAt - now)) or 0,
		eventNext = Config.EventDisplayNames[event.nextKind],
		eventNextIn = math.max(0, math.ceil(event.nextAt - now)),
	}
end

function EconomyService.pushSnapshot(player: Player)
	if not remotes then
		return
	end
	local snapshot = EconomyService.buildSnapshot(player)
	if snapshot then
		remotes.UpdateState:FireClient(player, snapshot)
	end
end

-- Buy a brainrot off the belt. The server validates everything: the brainrot
-- is still on the belt, the player can pay, has a free slot, and stands close.
function EconomyService.buyBrainrotFromConveyor(player: Player, record)
	local data = PlayerState.get(player)
	if not data then
		return
	end
	if record.state ~= "belt" or not record.model or not record.model.Parent then
		return -- someone else got it first
	end
	if not data.plotIndex then
		toast(player, "Kamu belum punya base")
		return
	end
	if data.cash < record.price then
		toast(player, string.format("Uang tidak cukup — %s harganya $%d", record.def.name, record.price))
		return
	end
	local slotIndex = PlayerState.firstFreeSlot(data)
	if PlayerState.freeSlotCount(data) < 1 or not slotIndex then
		toast(player, "Slot base penuh — beli slot dulu")
		return
	end
	local root = characterRoot(player)
	local body = record.model.PrimaryPart
	if not root or not body or (root.Position - body.Position).Magnitude > Config.BuyPromptDistance + 2 then
		toast(player, "Terlalu jauh dari brainrotnya")
		return
	end

	data.cash -= record.price
	ConveyorService.removeFromBelt(record)
	record.owner = player
	data.slots[slotIndex] = record -- reserve the slot while it walks home
	local plot = BaseService.getPlot(player)
	local pad = plot.pads[slotIndex]
	ConveyorService.sendBrainrotHome(record, pad.position, function()
		BaseService.placeBrainrotOnBaseSlot(player, record, slotIndex)
		StealService.attachStealPrompt(record)
	end)
	toast(player, string.format("%s dibeli! +$%d/detik", BrainrotFactory.displayName(record), record.income))
	EconomyService.pushSnapshot(player)
end

-- One second, one pay packet: base income x rebirth multiplier x event factor.
function EconomyService.tickIncomePerSecond()
	local factor = PlayerState.event.incomeFactor
	for player, data in pairs(PlayerState.players) do
		local baseIncome = 0
		for _, record in pairs(data.slots) do
			baseIncome += record.income
		end
		local earned = baseIncome * data.multiplier * factor
		data.cash += earned
		data.totalEarned += earned
		data.incomePerSecond = earned
		BaseService.updateBaseBoard(player)
		EconomyService.pushSnapshot(player)
	end
end

function EconomyService.init(remoteSet)
	remotes = remoteSet
	task.spawn(function()
		while true do
			task.wait(Config.TickSeconds)
			EconomyService.tickIncomePerSecond()
		end
	end)
end

return EconomyService
