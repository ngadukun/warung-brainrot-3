-- StealService.luau — stealing: hold E on a brainrot in someone else's
-- unlocked base, carry it home on your head, and it deposits itself when
-- you reach your own base. All checks are server-side.

local Config = require(script.Parent:WaitForChild("Config"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local StealService = {}

local toastRemote: RemoteEvent = nil

local function toast(player: Player, message: string)
	if toastRemote then
		toastRemote:FireClient(player, message)
	end
end

local function characterRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function setModelPhysics(model: Model, anchored: boolean)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = anchored
			descendant.CanCollide = false
			descendant.Massless = not anchored
		end
	end
end

-- The steal prompt rides on every brainrot standing on a base. It is only
-- enabled while that base is unlocked; the trigger re-validates anyway.
function StealService.attachStealPrompt(record)
	if record.stealPrompt then
		record.stealPrompt:Destroy()
		record.stealPrompt = nil
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Curi"
	local ownerName = record.owner and record.owner.DisplayName or "?"
	prompt.ObjectText = string.format("%s • Milik %s", BrainrotFactory.displayName(record), ownerName)
	prompt.HoldDuration = Config.StealHoldSeconds
	prompt.MaxActivationDistance = Config.StealPromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = record.model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		StealService.stealBrainrotFromBase(player, record)
	end)
	record.stealPrompt = prompt
end

function StealService.stealBrainrotFromBase(thief: Player, record)
	local thiefData = PlayerState.get(thief)
	local victim = record.owner
	if not thiefData or not victim or victim == thief then
		return
	end
	if record.state ~= "base" then
		return
	end
	local victimData = PlayerState.get(victim)
	if not victimData then
		return
	end
	if BaseService.isLocked(victim) then
		toast(thief, "Base itu lagi dikunci!")
		return
	end
	if thiefData.carrying then
		toast(thief, "Tanganmu sudah penuh — antar dulu ke base")
		return
	end
	if not thiefData.plotIndex or PlayerState.freeSlotCount(thiefData) < 1 then
		toast(thief, "Slot basemu penuh")
		return
	end
	local root = characterRoot(thief)
	local body = record.model and record.model.PrimaryPart
	if not root or not body or (root.Position - body.Position).Magnitude > Config.StealPromptDistance + 3 then
		return
	end

	-- Lift it out of the victim's slot and weld it onto the thief's head.
	victimData.slots[record.slot] = nil
	record.slot = nil
	record.owner = thief
	record.state = "carried"
	thiefData.carrying = record
	if record.stealPrompt then
		record.stealPrompt:Destroy()
		record.stealPrompt = nil
	end
	BaseService.refreshSlotPads(victim)

	local character = thief.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		StealService.dropCarriedBrainrot(thief, false)
		return
	end
	setModelPhysics(record.model, false)
	BrainrotFactory.placeAt(record, head.Position + Vector3.new(0, head.Size.Y / 2 + 0.1, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = record.model.PrimaryPart
	weld.Part1 = head
	weld.Parent = record.model.PrimaryPart

	toast(thief, string.format("Kamu mencuri %s! Antar ke basemu", BrainrotFactory.displayName(record)))
	toast(victim, string.format("%s dicuri dari basemu!", BrainrotFactory.displayName(record)))
end

-- The carried brainrot is lost: swept away by the wave, or its carrier left.
function StealService.dropCarriedBrainrot(player: Player, sweptAway: boolean)
	local data = PlayerState.get(player)
	if not data or not data.carrying then
		return
	end
	local record = data.carrying
	data.carrying = nil
	record.owner = nil
	PlayerState.removeBrainrot(record)
	if record.model then
		record.model:Destroy()
	end
	if sweptAway then
		toast(player, "Brainrot yang kamu bawa tersapu hujan krupuk!")
	end
end

-- Arriving home with a stolen brainrot puts it on a free base slot.
function StealService.depositCarriedBrainrot(player: Player)
	local data = PlayerState.get(player)
	if not data or not data.carrying then
		return
	end
	local slotIndex = PlayerState.firstFreeSlot(data)
	if not slotIndex then
		return
	end
	local record = data.carrying
	data.carrying = nil

	local body = record.model.PrimaryPart
	local weld = body and body:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	setModelPhysics(record.model, true)
	BaseService.placeBrainrotOnBaseSlot(player, record, slotIndex)
	StealService.attachStealPrompt(record)
	toast(player, string.format("%s aman di basemu! +$%d/detik", BrainrotFactory.displayName(record), record.income))
end

local function isInsideOwnPlot(player: Player): boolean
	local plot = BaseService.getPlot(player)
	local root = characterRoot(player)
	if not plot or not root then
		return false
	end
	return math.abs(root.Position.X - plot.center.X) <= 9 and math.abs(root.Position.Z - plot.center.Z) <= 9
end

function StealService.init(remotes)
	toastRemote = remotes and remotes.Toast

	-- Deposit checks and prompt lock states, a few times a second.
	task.spawn(function()
		while true do
			task.wait(0.3)
			for player, data in pairs(PlayerState.players) do
				if data.carrying and isInsideOwnPlot(player) then
					StealService.depositCarriedBrainrot(player)
				end
			end
			for record in pairs(PlayerState.brainrots) do
				if record.state == "base" and record.stealPrompt and record.owner then
					record.stealPrompt.Enabled = not BaseService.isLocked(record.owner)
				end
			end
		end
	end)
end

function StealService.handlePlayerLeaving(player: Player)
	StealService.dropCarriedBrainrot(player, false)
end

return StealService
