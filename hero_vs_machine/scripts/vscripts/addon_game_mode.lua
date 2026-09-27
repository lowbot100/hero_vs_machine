if CAddonPlayerRules == nil then
   CAddonPlayerRules = class({})
end

function Activate()
    GameRules.one = CAddonPlayerRules()
    GameRules.one:InitGameMode()
end

function CAddonPlayerRules:InitGameMode()
    print("Addon is loaded.")
    self.iDesiredRadiant = 10
    self.iDesiredDire = 0
    self.GOLDLOSS = false

    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, self.iDesiredRadiant)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, self.iDesiredDire)
    GameRules:GetGameModeEntity():SetThink("OnThink", self, "GlobalThink", 2)
    GameRules:GetGameModeEntity():SetLoseGoldOnDeath(self.GOLDLOSS)
end

function CAddonPlayerRules:OnThink()
    return 2
end

require("gold")
require("xp")
require("items/item_tpscroll")
