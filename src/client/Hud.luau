-- Hud.luau — the whole screen interface, built in code: top bar with cash,
-- income and rebirths, the three action buttons, an event chip, a centre
-- event banner, toasts and a hint line. Nothing sits in the top-left corner
-- (Roblox's own menu button lives there). The HUD only displays; buttons
-- call back into Game.client, which owns the remotes.

local Hud = {}

-- Indonesian thousand grouping: 1234567 -> "1.234.567".
local function formatMoney(value: number): string
	local digits = tostring(math.floor(value))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1."):reverse()
	if grouped:sub(1, 1) == "." then
		grouped = grouped:sub(2)
	end
	return grouped
end

local function makeLabel(parent: Instance, name: string, textSize: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextColor3 = color
	label.Text = ""
	label.Parent = parent
	return label
end

local function makeButton(parent: Instance, name: string, text: string): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 176, 0, 42)
	button.BackgroundColor3 = Color3.fromRGB(32, 38, 56)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = text
	button.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = button
	button.Parent = parent
	return button
end

function Hud.build(player: Player, callbacks)
	local gui = Instance.new("ScreenGui")
	gui.Name = "WarungHud"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5

	-- Top bar: cash | income per second | rebirths.
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.Position = UDim2.new(0.5, 0, 0, 8)
	topBar.Size = UDim2.new(0, 620, 0, 52)
	topBar.BackgroundColor3 = Color3.fromRGB(13, 16, 26)
	topBar.BackgroundTransparency = 0.12
	topBar.BorderSizePixel = 0
	local topCorner = Instance.new("UICorner")
	topCorner.CornerRadius = UDim.new(0, 10)
	topCorner.Parent = topBar
	topBar.Parent = gui

	local cashLabel = makeLabel(topBar, "Cash", 26, Color3.fromRGB(120, 255, 140))
	cashLabel.Position = UDim2.new(0, 18, 0, 0)
	cashLabel.Size = UDim2.new(0, 230, 1, 0)
	cashLabel.TextXAlignment = Enum.TextXAlignment.Left
	cashLabel.Text = "$150"

	local incomeLabel = makeLabel(topBar, "Income", 20, Color3.fromRGB(255, 255, 255))
	incomeLabel.Position = UDim2.new(0, 248, 0, 0)
	incomeLabel.Size = UDim2.new(0, 180, 1, 0)
	incomeLabel.Text = "$0/detik"

	local rebirthLabel = makeLabel(topBar, "Rebirths", 20, Color3.fromRGB(255, 210, 90))
	rebirthLabel.AnchorPoint = Vector2.new(1, 0)
	rebirthLabel.Position = UDim2.new(1, -18, 0, 0)
	rebirthLabel.Size = UDim2.new(0, 170, 1, 0)
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Right
	rebirthLabel.Text = "Rebirth: 0"

	-- Action buttons under the top bar.
	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "Buttons"
	buttonRow.AnchorPoint = Vector2.new(0.5, 0)
	buttonRow.Position = UDim2.new(0.5, 0, 0, 68)
	buttonRow.Size = UDim2.new(0, 620, 0, 42)
	buttonRow.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 12)
	layout.Parent = buttonRow
	buttonRow.Parent = gui

	local lockButton = makeButton(buttonRow, "LockButton", "Kunci Base")
	local slotButton = makeButton(buttonRow, "SlotButton", "Beli Slot $500")
	local rebirthButton = makeButton(buttonRow, "RebirthButton", "Rebirth")
	lockButton.MouseButton1Click:Connect(callbacks.lock)
	slotButton.MouseButton1Click:Connect(callbacks.buySlot)
	rebirthButton.MouseButton1Click:Connect(callbacks.rebirth)

	-- Event chip, top-right: the next event's countdown or the running one.
	local chip = Instance.new("Frame")
	chip.Name = "EventChip"
	chip.AnchorPoint = Vector2.new(1, 0)
	chip.Position = UDim2.new(1, -10, 0, 118)
	chip.Size = UDim2.new(0, 260, 0, 34)
	chip.BackgroundColor3 = Color3.fromRGB(13, 16, 26)
	chip.BackgroundTransparency = 0.25
	chip.BorderSizePixel = 0
	local chipCorner = Instance.new("UICorner")
	chipCorner.CornerRadius = UDim.new(0, 8)
	chipCorner.Parent = chip
	chip.Parent = gui
	local chipLabel = makeLabel(chip, "ChipText", 15, Color3.fromRGB(255, 235, 180))
	chipLabel.Size = UDim2.new(1, 0, 1, 0)
	chipLabel.Text = "Event berikut: ..."

	-- Centre event banner.
	local banner = Instance.new("Frame")
	banner.Name = "EventBanner"
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.new(0.5, 0, 0.3, 0)
	banner.Size = UDim2.new(0, 680, 0, 118)
	banner.BackgroundColor3 = Color3.fromRGB(140, 25, 25)
	banner.BackgroundTransparency = 0.08
	banner.BorderSizePixel = 0
	banner.Visible = false
	local bannerCorner = Instance.new("UICorner")
	bannerCorner.CornerRadius = UDim.new(0, 12)
	bannerCorner.Parent = banner
	banner.Parent = gui
	local bannerTitle = makeLabel(banner, "Title", 46, Color3.fromRGB(255, 255, 255))
	bannerTitle.Position = UDim2.new(0, 0, 0, 10)
	bannerTitle.Size = UDim2.new(1, 0, 0, 58)
	local bannerSub = makeLabel(banner, "Sub", 22, Color3.fromRGB(255, 235, 200))
	bannerSub.Position = UDim2.new(0, 0, 0, 70)
	bannerSub.Size = UDim2.new(1, 0, 0, 36)

	-- Carrying indicator under the buttons: shown while hauling a steal home.
	local carryingLabel = makeLabel(gui, "Carrying", 17, Color3.fromRGB(255, 190, 90))
	carryingLabel.AnchorPoint = Vector2.new(0.5, 0)
	carryingLabel.Position = UDim2.new(0.5, 0, 0, 116)
	carryingLabel.Size = UDim2.new(0, 620, 0, 26)
	carryingLabel.Visible = false

	-- Toast, bottom-right.
	local toastLabel = makeLabel(gui, "Toast", 16, Color3.fromRGB(255, 255, 255))
	toastLabel.AnchorPoint = Vector2.new(1, 1)
	toastLabel.Position = UDim2.new(1, -12, 1, -44)
	toastLabel.Size = UDim2.new(0, 360, 0, 40)
	toastLabel.BackgroundTransparency = 0.25
	toastLabel.BackgroundColor3 = Color3.fromRGB(13, 16, 26)
	toastLabel.TextWrapped = true
	toastLabel.Visible = false

	-- Hint line along the bottom.
	local hint = makeLabel(gui, "Hint", 16, Color3.fromRGB(215, 220, 232))
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, 0, 1, -8)
	hint.Size = UDim2.new(0, 760, 0, 24)
	hint.Text = "Dekati brainrot lalu tekan E untuk Beli / Curi — kunci base-mu sebelum diserang!"

	gui.Parent = player:WaitForChild("PlayerGui")

	local api = {}
	local toastToken = 0
	local bannerToken = 0

	function api.showToast(message: string)
		toastToken += 1
		local token = toastToken
		toastLabel.Text = message
		toastLabel.Visible = true
		task.delay(3.2, function()
			if toastToken == token then
				toastLabel.Visible = false
			end
		end)
	end

	function api.showBanner(payload)
		bannerToken += 1
		local token = bannerToken
		bannerTitle.Text = payload.title or ""
		bannerSub.Text = payload.sub or ""
		if string.find(payload.title or "", "DISKO") then
			banner.BackgroundColor3 = Color3.fromRGB(90, 30, 130)
		else
			banner.BackgroundColor3 = Color3.fromRGB(140, 25, 25)
		end
		banner.Visible = true
		task.delay(math.clamp(payload.seconds or 3, 2, 6), function()
			if bannerToken == token then
				banner.Visible = false
			end
		end)
	end

	function api.update(snapshot)
		cashLabel.Text = "$" .. formatMoney(snapshot.cash)
		local incomeText = "$" .. formatMoney(snapshot.income) .. "/detik"
		if snapshot.multiplier and snapshot.multiplier > 1 then
			incomeText ..= string.format(" ×%.1f", snapshot.multiplier)
		end
		incomeLabel.Text = incomeText
		rebirthLabel.Text = "Rebirth: " .. tostring(snapshot.rebirths)

		if snapshot.lockLeft and snapshot.lockLeft > 0 then
			lockButton.Text = "Terkunci " .. snapshot.lockLeft .. "d"
		elseif snapshot.lockCooldownLeft and snapshot.lockCooldownLeft > 0 then
			lockButton.Text = "Kunci (cd " .. snapshot.lockCooldownLeft .. "d)"
		else
			lockButton.Text = "Kunci Base"
		end

		if snapshot.nextSlotPrice and snapshot.nextSlotPrice > 0 then
			slotButton.Text = "Beli Slot $" .. formatMoney(snapshot.nextSlotPrice)
		else
			slotButton.Text = "Slot MAX"
		end

		if snapshot.canRebirth then
			rebirthButton.Text = "REBIRTH!"
			rebirthButton.BackgroundColor3 = Color3.fromRGB(200, 150, 30)
		else
			rebirthButton.Text = "Rebirth"
			rebirthButton.BackgroundColor3 = Color3.fromRGB(32, 38, 56)
		end

		if snapshot.eventActive then
			chipLabel.Text = string.format("%s aktif! %dd", snapshot.eventActive, snapshot.eventEndsIn or 0)
		else
			chipLabel.Text = string.format("Event berikut: %s • %dd", snapshot.eventNext or "...", snapshot.eventNextIn or 0)
		end

		if snapshot.carryingName then
			carryingLabel.Text = "Membawa " .. snapshot.carryingName .. " — antar pulang ke basemu!"
			carryingLabel.Visible = true
		else
			carryingLabel.Visible = false
		end
	end

	return api
end

return Hud
