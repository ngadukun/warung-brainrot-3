-- BrainrotFactory.luau — builds a brainrot character out of plain parts.
-- No external assets: body, head, eyes, a rarity prop, a neon glow disc and a
-- three-line BillboardGui label, all created here from a cast definition and
-- a mutation roll.

local Config = require(script.Parent:WaitForChild("Config"))

local BrainrotFactory = {}

local totalWeight = 0
for _, def in ipairs(Config.Cast) do
	totalWeight += def.weight
end

-- Weighted pick from the cast table (weights are normalised here).
function BrainrotFactory.pickRandomDefinition()
	local roll = math.random() * totalWeight
	local acc = 0
	for _, def in ipairs(Config.Cast) do
		acc += def.weight
		if roll <= acc then
			return def
		end
	end
	return Config.Cast[1]
end

-- Roll a mutation, or return the forced one (used by the tour showcase).
-- Returns nil for a plain, unmutated brainrot.
function BrainrotFactory.rollMutation(forcedKey: string?)
	if forcedKey then
		for _, mutation in ipairs(Config.Mutations) do
			if mutation.key == forcedKey then
				return mutation
			end
		end
		return nil
	end
	local roll = math.random()
	local acc = 0
	for _, mutation in ipairs(Config.Mutations) do
		acc += mutation.chance
		if roll <= acc then
			return mutation
		end
	end
	return nil
end

-- "★ GOLD Krupuk Terbang" for a mutated brainrot, plain name otherwise.
function BrainrotFactory.displayName(record): string
	if record.mutation then
		return record.mutation.prefix .. record.def.name
	end
	return record.def.name
end

local function makePart(name: string, size: Vector3, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = true
	return part
end

-- A little cap for Epic and up, a golden crown for Mythic and up.
local function addRarityProp(model: Model, def, scale: number, bodyTopY: number)
	local rarity = def.rarity
	if rarity == "Common" or rarity == "Rare" then
		return
	end
	if rarity == "Epic" or rarity == "Legendary" then
		local cap = makePart("Cap", Vector3.new(1.5 * scale, 0.45 * scale, 1.5 * scale), Color3.fromRGB(40, 40, 50))
		cap.Shape = Enum.PartType.Cylinder
		-- A cylinder's axis runs along X; rotate it flat so it sits as a cap.
		cap.CFrame = CFrame.new(0, bodyTopY + 0.85 * scale, 0) * CFrame.Angles(0, 0, math.rad(90))
		cap.Parent = model
		return
	end
	-- Crown: a gold band with four points.
	local gold = Color3.fromRGB(255, 205, 45)
	local band = makePart("CrownBand", Vector3.new(1.5 * scale, 0.4 * scale, 1.5 * scale), gold, Enum.Material.Metal)
	band.Position = Vector3.new(0, bodyTopY + 0.8 * scale, 0)
	band.Parent = model
	for i = 1, 4 do
		local angle = (i - 1) * math.pi / 2 + math.pi / 4
		local point = makePart("CrownPoint", Vector3.new(0.34 * scale, 0.6 * scale, 0.34 * scale), gold, Enum.Material.Metal)
		point.Position = Vector3.new(math.cos(angle) * 0.55 * scale, bodyTopY + 1.25 * scale, math.sin(angle) * 0.55 * scale)
		point.Parent = model
	end
end

local function buildLabel(model: Model, body: Part, record)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.new(0, 220, 0, 96)
	gui.StudsOffset = Vector3.new(0, 3.1, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = body

	local function line(name: string, text: string, y: number, size: number, color: Color3)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.BackgroundTransparency = 1
		label.Position = UDim2.new(0, 0, 0, y)
		label.Size = UDim2.new(1, 0, 0, size + 6)
		label.Font = Enum.Font.GothamBold
		label.Text = text
		label.TextSize = size
		label.TextColor3 = color
		label.TextStrokeTransparency = 0.35
		label.Parent = gui
		return label
	end

	line("NameLabel", BrainrotFactory.displayName(record), 0, 20, Color3.fromRGB(255, 255, 255))
	line("RarityLabel", record.def.rarity, 30, 16, Config.RarityColors[record.def.rarity])
	line("IncomeLabel", string.format("$%d/detik", record.income), 56, 18, Color3.fromRGB(140, 255, 150))

	gui.Parent = model
end

-- Place a brainrot so its feet rest exactly on `surfacePosition`. When
-- `facingPosition` is given the brainrot turns to face it (same height).
function BrainrotFactory.placeAt(record, surfacePosition: Vector3, facingPosition: Vector3?)
	local eye = surfacePosition + Vector3.new(0, record.feetOffset, 0)
	local frame
	if facingPosition then
		frame = CFrame.new(eye, Vector3.new(facingPosition.X, eye.Y, facingPosition.Z))
	else
		frame = CFrame.new(eye)
	end
	record.model:PivotTo(frame)
end

-- Build the model for a definition + mutation and wrap it in a record.
-- Use BrainrotFactory.placeAt to position it: the record knows how far the
-- Body's centre sits above the feet.
function BrainrotFactory.buildBrainrot(def, mutation)
	local scale = mutation and mutation.scale or 1
	local bodyColor = (mutation and mutation.color) or def.color

	local record = {
		model = nil,
		def = def,
		mutation = mutation,
		income = def.income * (mutation and mutation.factor or 1),
		price = def.price,
		state = "belt",
		owner = nil,
		slot = nil,
		beltZ = 0,
		feetOffset = 0, -- distance from the Body's centre down to the feet
	}

	local model = Instance.new("Model")
	model.Name = def.name

	-- Neon glow disc under the feet, coloured by rarity.
	local disc = makePart("GlowDisc", Vector3.new(3 * scale, 0.18, 3 * scale), Config.RarityColors[def.rarity], Enum.Material.Neon)
	disc.Shape = Enum.PartType.Cylinder
	disc.CFrame = CFrame.new(0, 0.09, 0) * CFrame.Angles(0, 0, math.rad(90))
	disc.Parent = model

	-- Body and head (the character faces +Z, the way it walks down the belt).
	local bodyHeight = 2.6 * scale
	local body = makePart("Body", Vector3.new(2.3 * scale, bodyHeight, 1.5 * scale), bodyColor)
	body.Position = Vector3.new(0, 0.18 + bodyHeight / 2, 0)
	body.Parent = model

	local headSize = 1.35 * scale
	local head = makePart("Head", Vector3.new(headSize, headSize, headSize), bodyColor:Lerp(Color3.fromRGB(255, 255, 255), 0.18))
	head.Position = Vector3.new(0, 0.18 + bodyHeight + headSize / 2, 0)
	head.Parent = model

	for _, side in ipairs({ -1, 1 }) do
		local eye = makePart("Eye", Vector3.new(0.22 * scale, 0.3 * scale, 0.1), Color3.fromRGB(15, 15, 20))
		eye.Position = Vector3.new(side * 0.32 * scale, head.Position.Y + 0.08 * scale, headSize / 2 + 0.02)
		eye.Parent = model
	end

	addRarityProp(model, def, scale, 0.18 + bodyHeight + headSize)

	model.PrimaryPart = body
	record.model = model
	record.feetOffset = 0.18 + bodyHeight / 2
	buildLabel(model, body, record)

	-- Rainbow brainrots cycle their body and head colours through the spectrum.
	if mutation and mutation.key == "Rainbow" then
		task.spawn(function()
			local hue = math.random()
			while model.Parent do
				hue = (hue + 0.01) % 1
				local color = Color3.fromHSV(hue, 0.75, 1)
				body.Color = color
				head.Color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.18)
				task.wait(0.08)
			end
		end)
	end

	return record
end

return BrainrotFactory
