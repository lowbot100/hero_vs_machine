-- 放在 game_mode.lua 或单独的 lua 文件里，require 进来

local suppress = {}

local function ShareTeamXP(keys)
    local gainPlayer = keys.player_id
    local xp = keys.experience

    -- 如果这次经验是我们自己发出去的，直接忽略，防止无限递归
    if suppress[gainPlayer] then return end

    -- 过滤：只处理真人 / 有效玩家
    if not PlayerResource:IsValidPlayerID(gainPlayer) then return end

    local team = PlayerResource:GetTeam(gainPlayer)
    if team ~= DOTA_TEAM_GOODGUYS and team ~= DOTA_TEAM_BADGUYS then return end

    for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if playerID ~= gainPlayer
           and PlayerResource:IsValidPlayerID(playerID)
           and PlayerResource:GetTeam(playerID) == team then
            local hero = PlayerResource:GetSelectedHeroEntity(playerID)
            if hero then
                suppress[playerID] = true
                -- 参数：经验值, 经验来源, 是否应用经验加成, 是否触发原版共享
                hero:AddExperience(xp, DOTA_ModifyXP_Unspecified, false, false)
                suppress[playerID] = nil
            end
        end
    end
end

ListenToGameEvent("dota_player_gain_hero_xp", ShareTeamXP, nil)