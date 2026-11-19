-- TourHelper.luau — reviewer helpers named by TOUR.json: stage the exact
-- screens the screenshots show (a mutation showcase on the belt, each world
-- event on demand) and hand out cash so a reviewer can play the full loop.

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ConveyorService = require(script.Parent:WaitForChild("ConveyorService"))
local EventService = require(script.Parent:WaitForChild("EventService"))

local TourHelper = {}

-- Put one named cast member on the belt, e.g. spawnBrainrot("Garuda Emas").
-- An optional second value forces a mutation: "Gold", "Diamond" or "Rainbow".
function TourHelper.spawnBrainrot(name: string, mutationKey: string?)
	return ConveyorService.spawnSpecific(tostring(name), mutationKey)
end

-- One Gold and one Diamond brainrot on the belt, ready for a close-up.
function TourHelper.spawnMutationShowcase()
	local gold = ConveyorService.spawnSpecific("Krupuk Terbang", "Gold")
	if gold then
		gold.beltZ = -6
	end
	local diamond = ConveyorService.spawnSpecific("Garuda Emas", "Diamond")
	if diamond then
		diamond.beltZ = 4
	end
end

-- Fire the Hujan Krupuk event (warning banner, then the wave).
function TourHelper.triggerWave()
	EventService.triggerKrupukWave()
end

-- Fire the Lampu Disko event (double income, cycling lights).
function TourHelper.triggerDisco()
	EventService.startDiscoLights()
end

-- Give every player in the server some spending money.
function TourHelper.grantCash(amount)
	local value = tonumber(amount) or 1000
	for _, data in pairs(PlayerState.players) do
		data.cash += value
	end
end

return TourHelper
