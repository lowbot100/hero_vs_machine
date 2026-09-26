-- DOTA2 Lua 实现：击杀奖励全额复制给同队所有队友，每个队员独立获得一份全额击杀金钱
-- 注册击杀事件监听，当任意玩家完成击杀后触发
ListenToGameEvent("entity_killed", Dynamic_Wrap(CTGameMode, "OnEntityKilled"), self)

-- 击杀事件处理函数
function OnEntityKilled(event)
    -- 从事件中取出死亡单位和击杀者ID
    local killedEntity = EntIndexToHScript(event.entindex_killed)
    local killerID = event.entindex_attacker
    
    -- 合法性过滤：没有击杀者/击杀者不是玩家单位时直接跳过
    if not killerID or killerID <= 0 then return end
    local killer = PlayerResource:GetPlayer(killerID - 1) -- 转换为DOTA2内部玩家ID格式
    if not killer then return end
    
    -- 获取击杀者所属队伍
    local killerTeam = PlayerResource:GetTeam(killerID - 1)
    -- 只处理天辉/夜魇两队，排除中立/裁判队伍
    if killerTeam ~= DOTA_TEAM_GOODGUYS and killerTeam ~= DOTA_TEAM_BADGUYS then return end

    -- 计算本次击杀的基础金钱奖励，和原版游戏击杀奖励保持一致
    local goldBounty = killedEntity:GetGoldBounty()
    -- 如果单位本身没有金钱奖励，直接跳过不需要处理
    if goldBounty <= 0 then return end

    -- 遍历同队所有玩家，每个玩家都获得一份全额击杀金钱
    local teamPlayerIDs = PlayerResource:GetTeamPlayers(killerTeam)
    for _, playerID in pairs(teamPlayerIDs) do
        -- 跳过离线玩家，只给存活在线的玩家发钱
        if not PlayerResource:IsPlayerConnected(playerID) then goto continue end
        local targetPlayer = PlayerResource:GetPlayer(playerID)
        if not targetPlayer then goto continue end

        -- DOTA2原生API发钱，保持和击杀金钱相同的规则：不可靠金钱，击杀奖励分类
        -- 这里让击杀者和队友都拿全额，就是题目要求的「每人复制一份」
        targetPlayer:ModifyGold(goldBounty, DOTA_ModifyGold_Kill, false)

        -- 调试日志，测试时取消注释可以看到发钱记录
         print(string.format("[团队击杀奖励] 击杀者队伍%d 玩家%d 获得全额击杀金%d", killerTeam, playerID, goldBounty))

        ::continue::
    end
end

-- ========== 可选配置：是否给击杀者额外发一份原版奖励 ==========
-- 默认逻辑：开启后击杀者原生会拿1份，这里再发1份，总共拿2倍，队友每人拿1份
-- 如果需要「总金额不变，击杀者不额外多拿，只给队友补一份」，把下面代码取消注释即可
--[[
function OnEntityKilled(event)
    ... 上面代码不变 ...
    -- 扣除击杀者原生已经拿到的那份奖励，保证总金额符合预期
    killer:ModifyGold(-goldBounty, DOTA_ModifyGold_Kill, false)
    -- 然后给所有人发一份全额，包括击杀者，总每人一份，总金额等于玩家数*单份
end
]]