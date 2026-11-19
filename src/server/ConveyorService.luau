-- ConveyorService.luau — the belt: spawns brainrots, walks them down the
-- conveyor, despawns them at the end, and moves bought brainrots home.
-- The Buy prompt lives here; what a purchase does is EconomyService's job,
-- wired in through setBuyHandler so the two services stay decoupled.

local RunService = game:GetService("RunService")

local Config = require(script.Parent:WaitForChild("Config"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))

local ConveyorService = {}

local beltRecords = {} -- records currently riding the belt
local movers = {} -- { record, from, to, duration, elapsed, onArrive }
local brainrotFolder: Folder = nil
local buyHandler = nil
local chevrons = {} -- neon arrows on the belt, pulsed in the heartbeat
local CHEVRON_LIT = Color3.fromRGB(255, 170, 40)
local CHEVRON_DIM = Color3.fromRGB(140, 85, 30)

function ConveyorService.setBuyHandler(handler)
	buyHandler = handler
end

local function countBelt(): number
	return #beltRecords
end

-- Put a fresh brainrot on the belt at the given Z (default: the north end).
function ConveyorService.spawnOnBelt(def, mutation, startZ: number?)
	local record = BrainrotFactory.buildBrainrot(def, mutation)
	record.state = "belt"
	record.beltZ = startZ or Config.BeltStartZ
	record.phase = math.random() * math.pi * 2

	local model = record.model
	model.Parent = brainrotFolder
	BrainrotFactory.placeAt(record, Vector3.new(Config.BeltX, Config.BeltSurfaceY, record.beltZ))

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Beli"
	prompt.ObjectText = string.format("%s — $%d", BrainrotFactory.displayName(record), record.price)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.BuyPromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if buyHandler then
			buyHandler(player, record)
		end
	end)
	record.buyPrompt = prompt

	PlayerState.addBrainrot(record)
	table.insert(beltRecords, record)
	return record
end

function ConveyorService.spawnRandom()
	local def = BrainrotFactory.pickRandomDefinition()
	local mutation = BrainrotFactory.rollMutation(nil)
	return ConveyorService.spawnOnBelt(def, mutation, nil)
end

-- Spawn one named cast member, optionally with a forced mutation key.
function ConveyorService.spawnSpecific(name: string, mutationKey: string?)
	local def = Config.CastByName[name]
	if not def then
		return nil
	end
	local mutation = mutationKey and BrainrotFactory.rollMutation(mutationKey) or nil
	return ConveyorService.spawnOnBelt(def, mutation, nil)
end

-- Take a brainrot off the belt (bought, or reached the end of the line).
function ConveyorService.removeFromBelt(record)
	for i, other in ipairs(beltRecords) do
		if other == record then
			table.remove(beltRecords, i)
			break
		end
	end
	if record.buyPrompt then
		record.buyPrompt:Destroy()
		record.buyPrompt = nil
	end
end

function ConveyorService.destroyBrainrot(record)
	ConveyorService.removeFromBelt(record)
	PlayerState.removeBrainrot(record)
	if record.model then
		record.model:Destroy()
	end
end

-- Walk a brainrot from where it stands to a surface position, then call back.
function ConveyorService.sendBrainrotHome(record, surfacePosition: Vector3, onArrive)
	local model = record.model
	local from = model.PrimaryPart.Position - Vector3.new(0, record.feetOffset, 0)
	local distance = (surfacePosition - from).Magnitude
	record.state = "walking"
	table.insert(movers, {
		record = record,
		from = from,
		to = surfacePosition,
		duration = math.max(0.7, distance / Config.WalkHomeSpeed),
		elapsed = 0,
		onArrive = onArrive,
	})
end

local function stepMovers(dt: number)
	for i = #movers, 1, -1 do
		local mover = movers[i]
		local record = mover.record
		if not record.model or not record.model.Parent then
			table.remove(movers, i)
		else
			mover.elapsed += dt
			local alpha = math.clamp(mover.elapsed / mover.duration, 0, 1)
			local pos = mover.from:Lerp(mover.to, alpha)
			local bob = math.sin(alpha * math.pi * 6) * 0.12
			local target = pos + Vector3.new(0, bob, 0)
			local facing = mover.to + Vector3.new(0, bob, 0)
			BrainrotFactory.placeAt(record, target, facing)
			if alpha >= 1 then
				table.remove(movers, i)
				if mover.onArrive then
					mover.onArrive()
				end
			end
		end
	end
end

local function stepBelt(dt: number)
	for i = #beltRecords, 1, -1 do
		local record = beltRecords[i]
		if not record.model or not record.model.Parent then
			table.remove(beltRecords, i)
		else
			record.beltZ += Config.BeltWalkSpeed * dt
			if record.beltZ >= Config.BeltEndZ then
				ConveyorService.destroyBrainrot(record)
			else
				local bob = math.abs(math.sin(os.clock() * 5 + record.phase)) * 0.15
				BrainrotFactory.placeAt(record, Vector3.new(Config.BeltX, Config.BeltSurfaceY + bob, record.beltZ))
			end
		end
	end
end

-- The belt's neon chevrons chase each other down the line, lit in turn.
local function pulseChevrons()
	local phase = math.floor(os.clock() * 2.5)
	for i, chevron in ipairs(chevrons) do
		chevron.Color = ((i + phase) % 3 == 0) and CHEVRON_LIT or CHEVRON_DIM
	end
end

function ConveyorService.init(world)
	chevrons = (world and world.chevrons) or {}
	brainrotFolder = Instance.new("Folder")
	brainrotFolder.Name = "Brainrots"
	brainrotFolder.Parent = workspace

	RunService.Heartbeat:Connect(function(dt)
		stepBelt(dt)
		stepMovers(dt)
		pulseChevrons()
	end)

	task.spawn(function()
		while true do
			task.wait(Config.BeltSpawnInterval)
			if countBelt() < Config.BeltMaxBrainrots then
				ConveyorService.spawnRandom()
			end
		end
	end)
end

return ConveyorService
