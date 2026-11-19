-- EventService.luau — the two rotating world events.
-- Hujan Krupuk: a warning banner, then a cream wave sweeps the market and
-- knocks anyone caught outside a base back to spawn, dropping their carry.
-- Lampu Disko: 30 seconds of double income while the market lights cycle.

local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local Config = require(script.Parent:WaitForChild("Config"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local StealService = require(script.Parent:WaitForChild("StealService"))

local EventService = {}

local world = nil
local remotes = nil
local originalAmbient: Color3 = nil
local originalFog: Color3 = nil
local bulbColors = {}

local function banner(title: string, sub: string, seconds: number)
	if remotes then
		remotes.EventWarning:FireAllClients({ title = title, sub = sub, seconds = seconds })
	end
end

local function toast(player: Player, message: string)
	if remotes then
		remotes.Toast:FireClient(player, message)
	end
end

local function isInsideAnyBase(rootPart: BasePart): boolean
	local margin = Config.BaseSafeMargin
	for _, plot in ipairs(PlayerState.plots) do
		if math.abs(rootPart.Position.X - plot.center.X) <= margin and math.abs(rootPart.Position.Z - plot.center.Z) <= margin then
			return true
		end
	end
	return false
end

-- Little crackers rain down while the wave crosses the market.
local function sprinkleKrupukBits(count: number)
	for _ = 1, count do
		local bit = Instance.new("Part")
		bit.Name = "KrupukBit"
		bit.Shape = Enum.PartType.Cylinder
		bit.Size = Vector3.new(1.3, 0.15, 1.3)
		bit.Color = Color3.fromRGB(246, 232, 196)
		bit.Material = Enum.Material.SmoothPlastic
		bit.Position = Vector3.new(math.random(-55, 55), 26, math.random(-55, 55))
		bit.CanCollide = true
		bit.Parent = workspace
		Debris:AddItem(bit, 5)
	end
end

-- The sweep itself: a translucent cream wall crosses the map south-bound.
local function sweepWave()
	local wave = Instance.new("Part")
	wave.Name = "KrupukWave"
	wave.Size = Vector3.new(130, 30, 4)
	wave.Color = Color3.fromRGB(246, 232, 196)
	wave.Transparency = 0.3
	wave.Material = Enum.Material.ForceField
	wave.Anchored = true
	wave.CanCollide = false
	wave.Position = Vector3.new(0, 12, -68)
	wave.Parent = workspace

	local hit = {}
	local elapsed = 0
	local sprinkled = 0
	while elapsed < Config.KrupukSweepSeconds do
		local dt = task.wait()
		elapsed += dt
		local alpha = math.clamp(elapsed / Config.KrupukSweepSeconds, 0, 1)
		local z = -68 + alpha * 136
		wave.Position = Vector3.new(0, 12, z)
		if sprinkled < 5 and alpha > sprinkled / 5 then
			sprinkled += 1
			sprinkleKrupukBits(7)
		end
		for player, data in pairs(PlayerState.players) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and not hit[player] and root.Position.Z <= z + 2 then
				hit[player] = true
				if not isInsideAnyBase(root) then
					if data.carrying then
						StealService.dropCarriedBrainrot(player, true)
					end
					root.CFrame = CFrame.new(world.spawnPos)
					toast(player, "Kamu tersapu hujan krupuk ke spawn!")
				end
			end
		end
	end
	wave:Destroy()
end

local function krupukSequence(warningSeconds: number)
	local event = PlayerState.event
	event.activeKind = "Krupuk"
	event.endsAt = PlayerState.now() + warningSeconds + Config.KrupukSweepSeconds
	banner("HUJAN KRUPUK!", "Lari pulang ke base kamu!", warningSeconds)
	task.wait(warningSeconds)
	sweepWave()
	event.activeKind = nil
	event.nextAt = PlayerState.now() + Config.EventInterval
	event.nextKind = "Disco"
end

-- Public: fire the krupuk event now (scheduler and TourHelper entry point).
function EventService.triggerKrupukWave()
	if PlayerState.event.activeKind then
		return
	end
	task.spawn(function()
		krupukSequence(Config.KrupukWarningSeconds)
	end)
end

-- Public: fire the disco now (scheduler and TourHelper entry point).
function EventService.startDiscoLights()
	local event = PlayerState.event
	if event.activeKind then
		return
	end
	event.activeKind = "Disco"
	event.endsAt = PlayerState.now() + Config.DiscoSeconds
	event.incomeFactor = Config.DiscoFactor
	banner("LAMPU DISKO!", "Pendapatan ×2 — lampu pasar berdisko!", 4)

	task.spawn(function()
		local hue = math.random()
		while PlayerState.event.activeKind == "Disco" and PlayerState.now() < event.endsAt do
			hue = (hue + 0.02) % 1
			Lighting.Ambient = Color3.fromHSV(hue, 0.45, 0.55)
			Lighting.FogColor = Color3.fromHSV(hue, 0.55, 0.3)
			for i, bulb in ipairs(world.stringLightBulbs) do
				bulb.Color = Color3.fromHSV((hue + i * 0.045) % 1, 0.7, 1)
			end
			task.wait(0.12)
		end
		Lighting.Ambient = originalAmbient
		Lighting.FogColor = originalFog
		for i, bulb in ipairs(world.stringLightBulbs) do
			bulb.Color = bulbColors[i]
		end
		event.incomeFactor = 1
		event.activeKind = nil
		event.nextAt = PlayerState.now() + Config.EventInterval
		event.nextKind = "Krupuk"
	end)
end

function EventService.init(worldRef, remoteSet)
	world = worldRef
	remotes = remoteSet
	originalAmbient = Lighting.Ambient
	originalFog = Lighting.FogColor
	for i, bulb in ipairs(world.stringLightBulbs) do
		bulbColors[i] = bulb.Color
	end

	-- The scheduler: when the countdown ends, fire whichever event is next.
	task.spawn(function()
		while true do
			task.wait(1)
			local event = PlayerState.event
			if not event.activeKind and PlayerState.now() >= event.nextAt then
				if event.nextKind == "Krupuk" then
					EventService.triggerKrupukWave()
				else
					EventService.startDiscoLights()
				end
			end
		end
	end)
end

return EventService
