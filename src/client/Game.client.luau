-- Game.client.luau — client bootstrap: builds the HUD and connects it to
-- the server. Buttons fire remotes; the server pushes snapshots, toasts and
-- event banners back. The client never keeps game state of its own.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local Hud = require(script.Parent:WaitForChild("Hud"))

local hud = Hud.build(player, {
	lock = function()
		remotesFolder:WaitForChild("ToggleLock"):FireServer()
	end,
	rebirth = function()
		remotesFolder:WaitForChild("Rebirth"):FireServer()
	end,
	buySlot = function()
		remotesFolder:WaitForChild("BuySlot"):FireServer()
	end,
})

remotesFolder:WaitForChild("UpdateState").OnClientEvent:Connect(function(snapshot)
	hud.update(snapshot)
end)

remotesFolder:WaitForChild("Toast").OnClientEvent:Connect(function(message)
	hud.showToast(message)
end)

remotesFolder:WaitForChild("EventWarning").OnClientEvent:Connect(function(payload)
	hud.showBanner(payload)
end)

-- Keyboard shortcut: L locks the base without reaching for the button.
ContextActionService:BindAction("ToggleBaseLock", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		remotesFolder:WaitForChild("ToggleLock"):FireServer()
	end
end, false, Enum.KeyCode.L)
