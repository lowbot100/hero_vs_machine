local building = Entities:FindByName(nil, "barracks_goodguy_1")

function GameMode:OnPlayerPickHero(keys)
    local hero = EntIndexToHScript(keys.heroindex)
    local player = EntIndexToHScript(keys.player)
    local playerID = hero:GetPlayerID()

    local building = Entities:FindByName(nil, "barracks_goodguy_1")
    building:SetOwner(hero)
    building:SetControllableByPlayer(playerID, true)
end