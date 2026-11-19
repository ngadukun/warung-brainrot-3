-- WorldBuilder.luau — builds the whole night market at server start:
-- conveyor, entrance arch, four base plots, spawn platform, stalls, trees,
-- lamps, fences, tents, lampion string lights, moon and stars. Pure
-- decoration and geometry; game rules live in the services.

local Config = require(script.Parent:WaitForChild("Config"))

local WorldBuilder = {}

local PLOT_DEFS = {
	{ name = "BASE BIRU", color = Color3.fromRGB(35, 95, 255), center = Vector3.new(0, 0, -48) },
	{ name = "BASE MERAH", color = Color3.fromRGB(230, 45, 45), center = Vector3.new(0, 0, 48) },
	{ name = "BASE KUNING", color = Color3.fromRGB(245, 200, 35), center = Vector3.new(48, 0, 0) },
	{ name = "BASE HIJAU", color = Color3.fromRGB(45, 200, 85), center = Vector3.new(-48, 0, 0) },
}

local STALLS = {
	{ pos = Vector3.new(-20, 0, -22), name = "WARUNG TEH", roof = Color3.fromRGB(230, 80, 60) },
	{ pos = Vector3.new(20, 0, -22), name = "SATE MADURA", roof = Color3.fromRGB(60, 180, 90) },
	{ pos = Vector3.new(-22, 0, 20), name = "BAKSO SOLO", roof = Color3.fromRGB(70, 130, 240) },
	{ pos = Vector3.new(22, 0, 20), name = "MIE AYAM", roof = Color3.fromRGB(245, 180, 40) },
	{ pos = Vector3.new(-34, 0, -14), name = "ES KELAPA", roof = Color3.fromRGB(240, 120, 180) },
	{ pos = Vector3.new(34, 0, 14), name = "SOTO LAMONGAN", roof = Color3.fromRGB(150, 90, 220) },
	{ pos = Vector3.new(-34, 0, 26), name = "TAHU BULAT", roof = Color3.fromRGB(60, 200, 200) },
	{ pos = Vector3.new(34, 0, -26), name = "NASI GORENG", roof = Color3.fromRGB(230, 140, 40) },
}

local LAMPION_COLORS = {
	Color3.fromRGB(255, 180, 80),
	Color3.fromRGB(255, 120, 120),
	Color3.fromRGB(255, 225, 130),
	Color3.fromRGB(150, 220, 255),
}

local function part(parent: Instance, name: string, size: Vector3, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function ball(parent: Instance, name: string, diameter: number, color: Color3, material: Enum.Material?): Part
	local p = part(parent, name, Vector3.new(diameter, diameter, diameter), color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

local function flatDisc(parent: Instance, name: string, diameter: number, height: number, color: Color3, material: Enum.Material?): Part
	local p = part(parent, name, Vector3.new(diameter, height, diameter), color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function billboard(parent: Instance, adornee: Instance, size: UDim2, offsetY: number): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = adornee
	gui.Parent = parent
	return gui
end

local function guiLine(gui: GuiObject, name: string, text: string, y: number, height: number, textSize: number, color: Color3)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 0, 0, y)
	label.Size = UDim2.new(1, 0, 0, height)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.4
	label.Parent = gui
	return label
end

-- The conveyor: dark belt, neon edges, chevron arrows, on a stone path.
local function buildConveyor(worldFolder: Folder, world)
	local folder = Instance.new("Folder")
	folder.Name = "Conveyor"
	folder.Parent = worldFolder

	local path = part(folder, "StonePath", Vector3.new(12, 0.2, 124), Color3.fromRGB(105, 95, 88))
	path.Position = Vector3.new(0, 0.1, 0)
	path.CanCollide = true

	local belt = part(folder, "Belt", Vector3.new(8, 0.2, 64), Color3.fromRGB(24, 24, 30))
	belt.Position = Vector3.new(Config.BeltX, 0.3, 0)

	for _, side in ipairs({ -1, 1 }) do
		local edge = part(folder, "BeltEdge", Vector3.new(0.3, 0.07, 64), Color3.fromRGB(255, 230, 60), Enum.Material.Neon)
		edge.Position = Vector3.new(Config.BeltX + side * 3.8, 0.43, 0)
	end

	world.chevrons = {}
	for i = 0, 9 do
		local z = -27 + i * 6
		for _, side in ipairs({ -1, 1 }) do
			local arm = part(folder, "Chevron", Vector3.new(0.45, 0.1, 2.4), Color3.fromRGB(255, 160, 40), Enum.Material.Neon)
			arm.CFrame = CFrame.new(Config.BeltX + side * 0.55, 0.44, z) * CFrame.Angles(0, side * math.rad(35), 0)
			table.insert(world.chevrons, arm)
		end
	end
end

-- One base plot: coloured floor, 10 slot pads with neon rings, a name board.
local function buildPlot(worldFolder: Folder, def, index: number)
	local folder = Instance.new("Folder")
	folder.Name = def.name
	folder.Parent = worldFolder

	local center = def.center
	local floor = part(folder, "Floor", Vector3.new(16, 0.4, 16), def.color:Lerp(Color3.fromRGB(0, 0, 0), 0.45))
	floor.Position = Vector3.new(center.X, 0.2, center.Z)
	floor.CanCollide = true

	-- Neon trim around the floor.
	for _, edge in ipairs({
		{ size = Vector3.new(16.4, 0.18, 0.35), pos = Vector3.new(center.X, 0.42, center.Z - 8.1) },
		{ size = Vector3.new(16.4, 0.18, 0.35), pos = Vector3.new(center.X, 0.42, center.Z + 8.1) },
		{ size = Vector3.new(0.35, 0.18, 16.4), pos = Vector3.new(center.X - 8.1, 0.42, center.Z) },
		{ size = Vector3.new(0.35, 0.18, 16.4), pos = Vector3.new(center.X + 8.1, 0.42, center.Z) },
	}) do
		local trim = part(folder, "Trim", edge.size, def.color, Enum.Material.Neon)
		trim.Position = edge.pos
	end

	local pads = {}
	for row = 0, 1 do
		for col = 0, 4 do
			local padPos = Vector3.new(center.X - 6 + col * 3, Config.PadSurfaceY, center.Z - 3.6 + row * 7.2)
			local ring = flatDisc(folder, "PadRing", 3.1, 0.16, Color3.fromRGB(110, 110, 110), Enum.Material.Neon)
			ring.CFrame = CFrame.new(padPos.X, 0.48, padPos.Z) * CFrame.Angles(0, 0, math.rad(90))
			local disc = flatDisc(folder, "Pad", 2.6, 0.3, Color3.fromRGB(52, 52, 60))
			disc.CFrame = CFrame.new(padPos.X, 0.55, padPos.Z) * CFrame.Angles(0, 0, math.rad(90))
			table.insert(pads, { disc = disc, ring = ring, position = padPos })
		end
	end

	-- Name board on the side facing the market centre.
	local toCenter = (Vector3.new(0, 0, 0) - center)
	local boardPos = center + Vector3.new(toCenter.X, 0, toCenter.Z).Unit * 9.5 + Vector3.new(0, 3.4, 0)
	local board = part(folder, "NameBoard", Vector3.new(11, 3.2, 0.4), Color3.fromRGB(20, 20, 28))
	board.CFrame = CFrame.new(boardPos, Vector3.new(0, 3.4, 0))
	for _, side in ipairs({ -1, 1 }) do
		local post = part(folder, "BoardPost", Vector3.new(0.35, 3.2, 0.35), Color3.fromRGB(60, 45, 35))
		post.Position = boardPos + board.CFrame.RightVector * side * 4.5 - Vector3.new(0, 1.8, 0)
	end
	local gui = billboard(folder, board, UDim2.new(0, 340, 0, 100), 0)
	guiLine(gui, "TitleLabel", def.name, 2, 44, 32, def.color)
	local incomeLabel = guiLine(gui, "IncomeLabel", "Kosong", 50, 36, 22, Color3.fromRGB(255, 255, 255))

	return {
		index = index,
		name = def.name,
		color = def.color,
		center = center,
		pads = pads,
		incomeLabel = incomeLabel,
		owner = nil,
	}
end

-- The entrance arch with the big WARUNG BRAINROT sign (the cover landmark).
local function buildArch(worldFolder: Folder)
	local folder = Instance.new("Folder")
	folder.Name = "Arch"
	folder.Parent = worldFolder

	local poleColor = Color3.fromRGB(150, 40, 35)
	for _, side in ipairs({ -1, 1 }) do
		local pole = part(folder, "Pole", Vector3.new(0.9, 10, 0.9), poleColor)
		pole.Position = Vector3.new(side * 6.5, 5, 38)
		pole.CanCollide = true
		local star = ball(folder, "Star", 1.7, Color3.fromRGB(255, 215, 60), Enum.Material.Neon)
		star.Position = Vector3.new(side * 6.5, 10.7, 38)
	end

	local board = part(folder, "SignBoard", Vector3.new(17, 4, 0.6), Color3.fromRGB(25, 20, 35))
	board.Position = Vector3.new(0, 11.8, 38)

	local neon = Color3.fromRGB(255, 190, 50)
	local top = part(folder, "SignFrame", Vector3.new(17.6, 0.35, 0.7), neon, Enum.Material.Neon)
	top.Position = Vector3.new(0, 13.9, 38)
	local bottom = part(folder, "SignFrame", Vector3.new(17.6, 0.35, 0.7), neon, Enum.Material.Neon)
	bottom.Position = Vector3.new(0, 9.7, 38)
	for _, side in ipairs({ -1, 1 }) do
		local sideBar = part(folder, "SignFrame", Vector3.new(0.35, 4.4, 0.7), neon, Enum.Material.Neon)
		sideBar.Position = Vector3.new(side * 8.6, 11.8, 38)
	end

	local gui = billboard(folder, board, UDim2.new(0, 560, 0, 140), 0)
	guiLine(gui, "Title", "✦ WARUNG BRAINROT ✦", 4, 62, 46, Color3.fromRGB(255, 205, 60))
	guiLine(gui, "Sub", "Pasar Malam Brainrot", 74, 40, 24, Color3.fromRGB(255, 255, 255))
end

local function buildSpawn(worldFolder: Folder, world)
	local platform = flatDisc(worldFolder, "SpawnPlatform", 10, 0.5, Color3.fromRGB(70, 80, 90))
	platform.CFrame = CFrame.new(22, 0.25, 0) * CFrame.Angles(0, 0, math.rad(90))
	platform.CanCollide = true

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(7, 0.5, 7)
	spawn.Position = Vector3.new(22, 0.75, 0)
	spawn.Color = Color3.fromRGB(40, 170, 170)
	spawn.Transparency = 0.3
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Parent = worldFolder

	world.spawnPos = Vector3.new(22, 2.5, 0)
end

local function buildStall(parent: Folder, def)
	local folder = Instance.new("Folder")
	folder.Name = def.name
	folder.Parent = parent

	-- Parts are placed through this frame so the stall faces the market centre.
	local facing = math.atan2(-def.pos.X, -def.pos.Z)
	local base = CFrame.new(def.pos) * CFrame.Angles(0, facing, 0)
	local function at(localPos: Vector3, extra: CFrame?): CFrame
		local frame = base * CFrame.new(localPos)
		if extra then
			frame = frame * extra
		end
		return frame
	end

	local counter = part(folder, "Counter", Vector3.new(6.5, 2.4, 3), Color3.fromRGB(120, 85, 55))
	counter.CFrame = at(Vector3.new(0, 1.2, 0))
	counter.CanCollide = true
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			local post = part(folder, "Post", Vector3.new(0.28, 3.6, 0.28), Color3.fromRGB(90, 65, 40))
			post.CFrame = at(Vector3.new(sx * 3.4, 1.8, sz * 1.9))
		end
	end
	local roof = part(folder, "Roof", Vector3.new(7.6, 0.35, 4.8), def.roof)
	roof.CFrame = at(Vector3.new(0, 4, 0), CFrame.Angles(math.rad(10), 0, 0))
	local lamp = ball(folder, "Lamp", 0.7, Color3.fromRGB(255, 220, 130), Enum.Material.Neon)
	lamp.CFrame = at(Vector3.new(0, 3.1, 1.8))
	local sign = part(folder, "Sign", Vector3.new(5.2, 1.1, 0.2), Color3.fromRGB(25, 22, 30))
	sign.CFrame = at(Vector3.new(0, 2.9, 2.05))
	local gui = billboard(folder, sign, UDim2.new(0, 240, 0, 52), 0)
	guiLine(gui, "Name", def.name, 4, 44, 22, Color3.fromRGB(255, 240, 200))
end

-- Lampion string lights: sagging rows of glowing bulbs between tall poles.
local function buildStringLights(worldFolder: Folder, world)
	local folder = Instance.new("Folder")
	folder.Name = "StringLights"
	folder.Parent = worldFolder
	world.stringLightBulbs = {}

	local strings = {
		{ a = Vector3.new(-28, 9.5, -14), b = Vector3.new(28, 9.5, -14) },
		{ a = Vector3.new(-28, 9.5, 14), b = Vector3.new(28, 9.5, 14) },
		{ a = Vector3.new(-14, 9.5, -28), b = Vector3.new(-14, 9.5, 28) },
		{ a = Vector3.new(14, 9.5, -28), b = Vector3.new(14, 9.5, 28) },
	}

	local poleAt = {}
	local function pole(pos: Vector3)
		local key = string.format("%d,%d", pos.X, pos.Z)
		if poleAt[key] then
			return
		end
		poleAt[key] = true
		local p = part(folder, "Pole", Vector3.new(0.35, 9.5, 0.35), Color3.fromRGB(70, 55, 40))
		p.Position = Vector3.new(pos.X, 4.75, pos.Z)
	end

	local bulbIndex = 0
	for _, s in ipairs(strings) do
		pole(s.a)
		pole(s.b)
		local previous = nil
		for i = 0, 12 do
			local t = i / 12
			local pos = s.a:Lerp(s.b, t)
			pos = Vector3.new(pos.X, pos.Y - math.sin(math.pi * t) * 2, pos.Z)
			if previous then
				local mid = (previous + pos) / 2
				local wire = part(folder, "Wire", Vector3.new(0.07, 0.07, (pos - previous).Magnitude), Color3.fromRGB(20, 20, 20))
				wire.CFrame = CFrame.new(mid, pos)
			end
			bulbIndex += 1
			local bulb = ball(folder, "LampionBulb", 0.55, LAMPION_COLORS[(bulbIndex % #LAMPION_COLORS) + 1], Enum.Material.Neon)
			bulb.Position = pos - Vector3.new(0, 0.35, 0)
			table.insert(world.stringLightBulbs, bulb)
			previous = pos
		end
	end
end

local function buildDecor(worldFolder: Folder)
	local folder = Instance.new("Folder")
	folder.Name = "Decor"
	folder.Parent = worldFolder

	for _, def in ipairs(STALLS) do
		buildStall(folder, def)
	end

	-- Trees: trunk plus a round canopy.
	local treeSpots = {
		{ -14, -34 }, { 14, -34 }, { -14, 34 }, { 14, 34 }, { -36, 0 }, { 36, 0 },
		{ -26, -8 }, { 26, 8 }, { -8, -26 }, { 8, 26 }, { -26, 30 }, { 26, -30 },
	}
	for _, spot in ipairs(treeSpots) do
		local trunk = part(folder, "Trunk", Vector3.new(0.7, 3.2, 0.7), Color3.fromRGB(95, 65, 40))
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Position = Vector3.new(spot[1], 1.6, spot[2])
		trunk.CanCollide = true
		local leaves = ball(folder, "Leaves", 4.4, Color3.fromRGB(35, 95, 40))
		leaves.Position = Vector3.new(spot[1], 4.8, spot[2])
	end

	-- Street lamps with real PointLights.
	local lampSpots = {
		{ -7, -24 }, { 7, -24 }, { -7, 0 }, { 7, 0 }, { -7, 24 }, { 7, 24 },
		{ -24, -24 }, { 24, 24 }, { -24, 24 }, { 24, -24 },
	}
	for _, spot in ipairs(lampSpots) do
		local pole = part(folder, "LampPole", Vector3.new(0.28, 6, 0.28), Color3.fromRGB(45, 45, 55))
		pole.Shape = Enum.PartType.Cylinder
		pole.Position = Vector3.new(spot[1], 3, spot[2])
		local head = ball(folder, "LampHead", 0.95, Color3.fromRGB(255, 205, 120), Enum.Material.Neon)
		head.Position = Vector3.new(spot[1], 6.2, spot[2])
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 190, 110)
		light.Range = 20
		light.Brightness = 2
		light.Parent = head
	end

	-- Umbrella tents.
	local tentSpots = {
		{ -16, -14, Color3.fromRGB(230, 90, 90) }, { 16, -14, Color3.fromRGB(90, 160, 230) },
		{ -16, 14, Color3.fromRGB(240, 200, 60) }, { 16, 14, Color3.fromRGB(120, 220, 130) },
		{ -28, 28, Color3.fromRGB(200, 120, 240) }, { 28, -28, Color3.fromRGB(240, 150, 70) },
	}
	for _, spot in ipairs(tentSpots) do
		local pole = part(folder, "TentPole", Vector3.new(0.22, 3.6, 0.22), Color3.fromRGB(80, 70, 60))
		pole.Shape = Enum.PartType.Cylinder
		pole.Position = Vector3.new(spot[1], 1.8, spot[2])
		local canopy = ball(folder, "TentCanopy", 5.5, spot[3])
		canopy.Size = Vector3.new(5.5, 1.5, 5.5)
		canopy.Position = Vector3.new(spot[1], 4, spot[2])
		local tableTop = part(folder, "TentTable", Vector3.new(2.2, 0.25, 2.2), Color3.fromRGB(130, 100, 70))
		tableTop.Position = Vector3.new(spot[1], 1, spot[2])
	end

	-- Crates and barrels beside the stalls.
	for i, spot in ipairs({ { -17, -19 }, { 18, -25 }, { -25, 17 }, { 25, 23 }, { -31, -11 }, { 31, 11 } }) do
		if i % 2 == 0 then
			local barrel = part(folder, "Barrel", Vector3.new(1.3, 2, 1.3), Color3.fromRGB(110, 75, 45))
			barrel.Shape = Enum.PartType.Cylinder
			barrel.CFrame = CFrame.new(spot[1], 1, spot[2]) * CFrame.Angles(0, 0, math.rad(90))
			barrel.CanCollide = true
		else
			local crate = part(folder, "Crate", Vector3.new(1.9, 1.9, 1.9), Color3.fromRGB(140, 105, 65))
			crate.Position = Vector3.new(spot[1], 0.95, spot[2])
			crate.CanCollide = true
		end
	end

	-- Low fence around the market edge.
	local fenceColor = Color3.fromRGB(85, 60, 40)
	for _, side in ipairs({ -1, 1 }) do
		for _, axis in ipairs({ "X", "Z" }) do
			local railA = part(folder, "FenceRail", Vector3.new(0.25, 0.25, 0.25), fenceColor)
			local railB = part(folder, "FenceRail", Vector3.new(0.25, 0.25, 0.25), fenceColor)
			if axis == "X" then
				railA.Size = Vector3.new(124, 0.25, 0.25)
				railB.Size = Vector3.new(124, 0.25, 0.25)
				railA.Position = Vector3.new(0, 1.35, side * 62)
				railB.Position = Vector3.new(0, 0.75, side * 62)
			else
				railA.Size = Vector3.new(0.25, 0.25, 124)
				railB.Size = Vector3.new(0.25, 0.25, 124)
				railA.Position = Vector3.new(side * 62, 1.35, 0)
				railB.Position = Vector3.new(side * 62, 0.75, 0)
			end
		end
		for i = -6, 6 do
			local postA = part(folder, "FencePost", Vector3.new(0.4, 1.6, 0.4), fenceColor)
			postA.Position = Vector3.new(i * 10, 0.8, side * 62)
			local postB = part(folder, "FencePost", Vector3.new(0.4, 1.6, 0.4), fenceColor)
			postB.Position = Vector3.new(side * 62, 0.8, i * 10)
		end
	end

	-- Moon and a field of stars.
	local moon = ball(folder, "Moon", 13, Color3.fromRGB(228, 233, 255), Enum.Material.Neon)
	moon.Position = Vector3.new(85, 68, -115)
	for _ = 1, 70 do
		local dir = Vector3.new(math.random() * 2 - 1, math.random() * 0.75 + 0.3, math.random() * 2 - 1).Unit
		local star = ball(folder, "Star", 0.7, Color3.fromRGB(235, 240, 255), Enum.Material.Neon)
		star.Position = dir * 190 + Vector3.new(0, 8, 0)
	end
end

-- Build everything and return the world table the services work with.
function WorldBuilder.build()
	local worldFolder = Instance.new("Folder")
	worldFolder.Name = "World"
	worldFolder.Parent = workspace

	local world = { plots = {}, chevrons = {}, stringLightBulbs = {}, spawnPos = Vector3.new(22, 2.5, 0) }

	buildConveyor(worldFolder, world)
	buildArch(worldFolder)
	buildSpawn(worldFolder, world)
	buildStringLights(worldFolder, world)
	buildDecor(worldFolder)

	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = worldFolder
	for index, def in ipairs(PLOT_DEFS) do
		world.plots[index] = buildPlot(plotsFolder, def, index)
	end

	return world
end

return WorldBuilder
