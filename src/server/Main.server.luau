-- Main.server.luau — Warung Brainrot bootstrap.
-- Builds the world, starts every service, wires the client remotes to the
-- services that own them, and manages the player lifecycle.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local BaseService = require(script.Parent:WaitForChild("BaseService"))
local ConveyorService = require(script.Parent:WaitForChild("ConveyorService"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local StealService = require(script.Parent:WaitForChild("StealService"))
local EventService = require(script.Parent:WaitForChild("EventService"))
local RebirthService = require(script.Parent:WaitForChild("RebirthService"))
local TourHelper = require(script.Parent:WaitForChild("TourHelper"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local remotes = {
	ToggleLock = remotesFolder:WaitForChild("ToggleLock"),
	Rebirth = remotesFolder:WaitForChild("Rebirth"),
	BuySlot = remotesFolder:WaitForChild("BuySlot"),
	UpdateState = remotesFolder:WaitForChild("UpdateState"),
	Toast = remotesFolder:WaitForChild("Toast"),
	EventWarning = remotesFolder:WaitForChild("EventWarning"),
}

local world = WorldBuilder.build()

BaseService.init(world, remotes)
ConveyorService.init(world)
StealService.init(remotes)
EconomyService.init(remotes)
EventService.init(world, remotes)
RebirthService.init(remotes)
ConveyorService.setBuyHandler(function(player, record)
	EconomyService.buyBrainrotFromConveyor(player, record)
end)

-- TourHelper is passive (reviewers call it through TOUR.json); touch it once
-- here so a broken helper fails loudly at startup, not on tour day.
assert(TourHelper.spawnMutationShowcase ~= nil, "TourHelper failed to load")

-- Client -> server remotes, one owner each.
remotes.ToggleLock.OnServerEvent:Connect(function(player)
	BaseService.lockBaseWithCooldown(player)
	EconomyService.pushSnapshot(player)
end)
remotes.Rebirth.OnServerEvent:Connect(function(player)
	RebirthService.rebirthForMultiplier(player)
	EconomyService.pushSnapshot(player)
end)
remotes.BuySlot.OnServerEvent:Connect(function(player)
	BaseService.buyExtraSlot(player)
	EconomyService.pushSnapshot(player)
end)

local function onPlayerAdded(player: Player)
	PlayerState.registerPlayer(player)
	BaseService.assignPlot(player)
end

local function onPlayerRemoving(player: Player)
	StealService.handlePlayerLeaving(player)
	BaseService.releasePlot(player)
	PlayerState.removePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("[Warung Brainrot] pasar malam buka — world built, services running")
