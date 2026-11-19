-- BaseService.luau — base plots: who owns which plot, which brainrot stands
-- on which pad, pad glow colours, the base lock and buying extra slots.

local Config = require(script.Parent:WaitForChild("Config"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local BaseService = {}

local toastRemote: RemoteEvent = nil

local function toast(player: Player, message: string)
	if toastRemote then
		toastRemote:FireClient(player, message)
	end
end

function BaseService.init(world, remotes)
	toastRemote = remotes and remotes.Toast
	for index, plot in ipairs(world.plots) do
		PlayerState.plots[index] = plot
	end
end

function BaseService.getPlot(player: Player)
	local data = PlayerState.get(player)
	if not data or not data.plotIndex then
		return nil
	end
	return PlayerState.plots[data.plotIndex]
end

-- Give the player the first unclaimed plot, in join order.
function BaseService.assignPlot(player: Player)
	local data = PlayerState.get(player)
	if not data or data.plotIndex then
		return
	end
	for index, plot in ipairs(PlayerState.plots) do
		if plot.owner == nil then
			plot.owner = player
			data.plotIndex = index
			BaseService.refreshSlotPads(player)
			BaseService.updateBaseBoard(player)
			toast(player, "Base kamu: " .. plot.name)
			return
		end
	end
	toast(player, "Semua base penuh — jadi penonton dulu ya")
end

-- Pad rings glow with the rarity colour of the brainrot standing on them,
-- grey when empty, and pads past the player's slot count stay dimmed.
function BaseService.refreshSlotPads(player: Player)
	local data = PlayerState.get(player)
	local plot = BaseService.getPlot(player)
	if not data or not plot then
		return
	end
	for slotIndex, pad in ipairs(plot.pads) do
		local record = data.slots[slotIndex]
		if slotIndex > data.slotCount then
			pad.ring.Color = Color3.fromRGB(45, 45, 50)
			pad.disc.Transparency = 0.55
		elseif record then
			pad.ring.Color = Config.RarityColors[record.def.rarity]
			pad.disc.Transparency = 0
		else
			pad.ring.Color = Color3.fromRGB(110, 110, 110)
			pad.disc.Transparency = 0
		end
	end
end

-- Put a brainrot onto a reserved base slot: state, position, pad glow.
function BaseService.placeBrainrotOnBaseSlot(player: Player, record, slotIndex: number)
	local data = PlayerState.get(player)
	local plot = BaseService.getPlot(player)
	if not data or not plot then
		return
	end
	record.state = "base"
	record.owner = player
	record.slot = slotIndex
	data.slots[slotIndex] = record
	local pad = plot.pads[slotIndex]
	BrainrotFactory.placeAt(record, pad.position, Vector3.new(0, pad.position.Y, 0))
	BaseService.refreshSlotPads(player)
end

-- Destroy every brainrot standing on the player's base (rebirth, leaving).
function BaseService.clearBaseBrainrots(player: Player)
	local data = PlayerState.get(player)
	if not data then
		return
	end
	for slotIndex, record in pairs(data.slots) do
		data.slots[slotIndex] = nil
		PlayerState.removeBrainrot(record)
		if record.model then
			record.model:Destroy()
		end
	end
	BaseService.refreshSlotPads(player)
end

-- The player leaves: free the plot and clear everything they owned there.
function BaseService.releasePlot(player: Player)
	local data = PlayerState.get(player)
	if not data then
		return
	end
	BaseService.clearBaseBrainrots(player)
	local plot = BaseService.getPlot(player)
	if plot then
		plot.owner = nil
		plot.incomeLabel.Text = "Kosong"
	end
	data.plotIndex = nil
end

-- The name board over a base shows its owner and live income per second.
function BaseService.updateBaseBoard(player: Player)
	local data = PlayerState.get(player)
	local plot = BaseService.getPlot(player)
	if not data or not plot then
		return
	end
	local text = string.format("%s • $%d/detik", player.DisplayName, math.floor(data.incomePerSecond))
	if PlayerState.isLocked(data) then
		text ..= " • TERKUNCI"
	end
	plot.incomeLabel.Text = text
end

-- Kunci Base: lock the base for LockSeconds; the cooldown runs from the press.
function BaseService.lockBaseWithCooldown(player: Player)
	local data = PlayerState.get(player)
	if not data or not data.plotIndex then
		toast(player, "Kamu belum punya base")
		return
	end
	local now = PlayerState.now()
	if now < data.lockCooldownUntil then
		toast(player, string.format("Kunci cooldown: %d detik lagi", math.ceil(data.lockCooldownUntil - now)))
		return
	end
	data.lockUntil = now + Config.LockSeconds
	data.lockCooldownUntil = now + Config.LockCooldownSeconds
	toast(player, string.format("Base terkunci %d detik!", Config.LockSeconds))
end

function BaseService.isLocked(player: Player): boolean
	return PlayerState.isLocked(PlayerState.get(player))
end

-- Buy one more base slot at the rising price.
function BaseService.buyExtraSlot(player: Player)
	local data = PlayerState.get(player)
	if not data or not data.plotIndex then
		toast(player, "Kamu belum punya base")
		return
	end
	local price = PlayerState.nextSlotPrice(data)
	if not price then
		toast(player, "Slot base sudah maksimum")
		return
	end
	if data.cash < price then
		toast(player, string.format("Uang kurang: slot berikutnya $%d", price))
		return
	end
	data.cash -= price
	data.slotCount += 1
	BaseService.refreshSlotPads(player)
	toast(player, string.format("Slot base sekarang %d!", data.slotCount))
end

return BaseService
