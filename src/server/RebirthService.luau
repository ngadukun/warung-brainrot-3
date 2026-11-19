-- RebirthService.luau — rebirth: at $25,000 total earned, cash and brainrots
-- reset in exchange for a permanent, stacking +50% income multiplier.

local Config = require(script.Parent:WaitForChild("Config"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local StealService = require(script.Parent:WaitForChild("StealService"))

local RebirthService = {}

local toastRemote: RemoteEvent = nil

local function toast(player: Player, message: string)
	if toastRemote then
		toastRemote:FireClient(player, message)
	end
end

function RebirthService.rebirthForMultiplier(player: Player)
	local data = PlayerState.get(player)
	if not data then
		return
	end
	if data.totalEarned < Config.RebirthThreshold then
		toast(player, string.format(
			"Rebirth butuh total pendapatan $%d — kamu baru $%d",
			Config.RebirthThreshold,
			math.floor(data.totalEarned)
		))
		return
	end

	if data.carrying then
		StealService.dropCarriedBrainrot(player, false)
	end
	BaseService.clearBaseBrainrots(player)

	data.cash = Config.StartCash
	data.totalEarned = 0
	data.incomePerSecond = 0
	data.rebirths += 1
	data.multiplier = 1 + Config.RebirthMultiplierStep * data.rebirths
	-- A fresh start gets a short grace lock so the empty base is not raided
	-- the second it resets; the normal lock cooldown is waived this once.
	data.lockUntil = PlayerState.now() + 10
	data.lockCooldownUntil = 0
	BaseService.updateBaseBoard(player)
	toast(player, string.format("REBIRTH! Pengali pendapatan permanen sekarang ×%.1f", data.multiplier))
end

function RebirthService.init(remotes)
	toastRemote = remotes and remotes.Toast
end

return RebirthService
