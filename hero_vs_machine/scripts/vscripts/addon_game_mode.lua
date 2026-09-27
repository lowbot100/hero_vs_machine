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

    -- 加载需要的脚本（确保这个文件存在：scripts/vscripts/modifiers/modifier_custom_fountain.lua）
    require("modifiers.modifier_custom_fountain")

    -- 在地图实体加载后给地图中的所有泉水应用光环
    local tries = 0
    GameRules:GetGameModeEntity():SetContextThink("ApplyCustomFountainBuffs_Init", function()
        tries = tries + 1
        ApplyCustomFountainBuffs()
        -- 如果还没找到/应用也不要一直重试太多次，尝试 10 次（每次间隔 0.5s）
        if tries < 10 then
            return 0.5
        end
        return nil
    end, 0.5)
end

function CAddonPlayerRules:OnThink()
    return 2
end

require("gold")
require("xp")
require("items/item_tpscroll")
