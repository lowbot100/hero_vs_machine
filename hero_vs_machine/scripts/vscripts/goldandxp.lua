-- 自定义经验曲线参数（可调）
    self.XPBase = 250    -- 基础经验：低等级每级所需的基础经验（影响前期升级速度）。增大此值会使每一级基础需求变大。
    self.XPGrowth = 180  -- 成长系数：决定经验需求的二次项增长速度（影响后期曲线陡峭度）。增大此值会使高级别所需经验成倍上升。
    -- 最大英雄等级（若想使用自定义经验表，可在此限制等级）
    self.MaxHeroLevel = 50
    
-- =======================
-- 团队共享金钱与经验（切换）
    -- 若启用：当一名玩家获得金钱/经验，队伍中其他在线玩家也会按模式获得对应的共享奖励
    self.TeamSharedGoldXP = true
    -- TeamShareMirror = true 表示“镜像”来源玩家真实获得量（通常用于击杀/拾取等）
    self.TeamShareMirror = true
    -- TeamShareAverage = true 表示把来源玩家获得的总额按队伍在线人数平均分摊
    -- 若为 false，则按“每人获得相同值”的方式（旧行为）
    self.TeamShareAverage = true
    -- 是否使用可靠金钱发放（ModifyGold 的 reliable 参数）
    self.TeamShareUseReliableGold = true
    -- 是否排除奖励来源玩家本身（通常为 true）
    self.TeamShareExcludeKiller = true
-- ========== 团队共享变化检测用的内部快照（用于任意奖励事件自动镜像） ==========
    -- PlayerResource 的金钱/英雄经验会被周期性采样，对比差值以识别“谁获得了多少奖励”并进行镜像分发
    self.PlayerGoldSnapshot = {}
    self.PlayerXPSnapshot = {}
    self.IgnoreGoldFor = {}  -- 用于标记刚由分享分发导致的金钱变化，下一次采样时应忽略（防止回路）
    self.IgnoreXPFor = {}

    -- 初始化快照（若尚未在 OnThink 中设置，会在首轮 OnThink 时补齐）
    if PlayerResource then
        for playerID = 0, DOTA_MAX_PLAYERS - 1 do
            if PlayerResource:IsValidPlayerID(playerID) then
                local g = 0
                if PlayerResource.GetGold then
                    g = PlayerResource:GetGold(playerID)
                end
                self.PlayerGoldSnapshot[playerID] = g

                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                if hero and hero.GetCurrentXP then
                    self.PlayerXPSnapshot[playerID] = hero:GetCurrentXP()
                else
                    self.PlayerXPSnapshot[playerID] = 0
                end

                self.IgnoreGoldFor[playerID] = false
                self.IgnoreXPFor[playerID] = false
            end
        end
    end
-- 通用函数：从指定玩家来源分发团队奖励（任意奖励事件可直接调用）
-- 参数：sourcePlayerID -> 奖励来源玩家 ID
--       goldAmount -> 要给予的金钱总量或每人数量，取决于 TeamShareAverage 配置
--       xpAmount -> 要给予的经验总量或每人数量，取决于 TeamShareAverage 配置
--       excludeSource -> 是否排除奖励来源玩家本身（true 表示不发给来源玩家）
function CAddonPlayerRules:ShareTeamRewardFromPlayer(sourcePlayerID, goldAmount, xpAmount, excludeSource)
    if not sourcePlayerID or not PlayerResource or not PlayerResource:IsValidPlayerID(sourcePlayerID) then return end

    local sourceTeam = PlayerResource:GetTeam(sourcePlayerID)

    -- 收集接收者列表（符合队伍、有效玩家、真实英雄）
    local recipients = {}
    for playerID = 0, DOTA_MAX_PLAYERS - 1 do
        if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:GetTeam(playerID) == sourceTeam then
            if excludeSource and playerID == sourcePlayerID then
                -- 排除来源
            else
                local allyHero = PlayerResource:GetSelectedHeroEntity(playerID)
                if allyHero ~= nil and allyHero:IsRealHero() then
                    table.insert(recipients, playerID)
                end
            end
        end
    end

    local recipientCount = #recipients
    if recipientCount == 0 then return end

    -- 决定每位接收者应得的数额：按配置支持平均分摊或按人镜像
    local perGold = 0
    local perXP = 0
    if goldAmount and goldAmount > 0 then
        if self.TeamShareAverage then
            perGold = math.floor(goldAmount / recipientCount)
        else
            -- 非平均：每人获得相同的数额（旧行为）
            perGold = goldAmount
        end
    end
    if xpAmount and xpAmount > 0 then
        if self.TeamShareAverage then
            perXP = math.floor(xpAmount / recipientCount)
        else
            perXP = xpAmount
        end
    end

    -- 分发给每位接收者
    for _, pid in ipairs(recipients) do
        local allyHero = PlayerResource:GetSelectedHeroEntity(pid)
        if allyHero ~= nil and allyHero:IsRealHero() then
            if perXP and perXP > 0 then
                allyHero:AddExperience(perXP, DOTA_ModifyXP_CreepKill, false, true)
                -- 标记以便下一轮采样忽略该次 XP 增加（防止镜像回路）
                self.IgnoreXPFor[pid] = true
            end
            if perGold and perGold > 0 then
                -- 使用可靠金钱或非可靠金钱由配置决定
                local reliable = (self.TeamShareUseReliableGold == true)
                PlayerResource:ModifyGold(pid, perGold, reliable, 0)
                -- 标记以便下一轮采样忽略该次金钱变化
                self.IgnoreGoldFor[pid] = true
            end
            print(string.format("ShareTeamReward: gave player %d +%d XP +%d gold (mode average=%s reliable=%s)", pid, perXP or 0, perGold or 0, tostring(self.TeamShareAverage), tostring(self.TeamShareUseReliableGold)))
        end
    end

    -- 防止来源玩家的原始增量被 OnThink 再次检测并镜像（当我们刚用镜像/分发时会产生来源玩家本地变化）
    if PlayerResource:IsValidPlayerID(sourcePlayerID) then
        self.IgnoreGoldFor[sourcePlayerID] = true
        self.IgnoreXPFor[sourcePlayerID] = true
    end
end

-- 便捷全局函数：其他脚本可以直接调用 ShareTeamReward(sourcePlayerID, gold, xp, exclude)
function ShareTeamReward(sourcePlayerID, goldAmount, xpAmount, excludeSource)
    if GameRules and GameRules.Addon and GameRules.Addon.ShareTeamRewardFromPlayer then
        GameRules.Addon:ShareTeamRewardFromPlayer(sourcePlayerID, goldAmount or 0, xpAmount or 0, excludeSource == nil and true or excludeSource)
    else
        print("ShareTeamReward: GameRules.Addon not available")
    end
end

-- OnThink 是我们周期性运行的定时器回调
-- 返回值为下一次调用的时间（秒）。返回 nil 或 -1 可以停止定时器
function CAddonPlayerRules:OnThink()
    -- 这里放入你想要每 X 秒检查一次的逻辑，例如日志、状态检查或自动事件触发
    -- 注意：不要把耗时操作放在这里，会影响游戏性能

    -- 自动检测玩家金钱/经验变化并镜像（如果启用了 TeamShareMirror）
    if self.TeamSharedGoldXP and self.TeamShareMirror and PlayerResource then
        for playerID = 0, DOTA_MAX_PLAYERS - 1 do
            if PlayerResource:IsValidPlayerID(playerID) then
                -- 当前金钱
                local currentGold = 0
                if PlayerResource.GetGold then
                    currentGold = PlayerResource:GetGold(playerID)
                end
                local lastGold = self.PlayerGoldSnapshot[playerID] or 0
                local deltaGold = currentGold - lastGold

                -- 当前经验（取选中英雄的当前 XP）
                local xp = 0
                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                if hero and hero.GetCurrentXP then
                    xp = hero:GetCurrentXP()
                end
                local lastXP = self.PlayerXPSnapshot[playerID] or 0
                local deltaXP = xp - lastXP

                -- 如果本轮是因为分享而产生的变化，则清理标记并同步快照，不做二次分享
                if self.IgnoreGoldFor[playerID] then
                    self.IgnoreGoldFor[playerID] = false
                    deltaGold = 0
                end
                if self.IgnoreXPFor[playerID] then
                    self.IgnoreXPFor[playerID] = false
                    deltaXP = 0
                end

                -- 仅在正增长时触发镜像分享（避免处理消耗或负变动）
                local shareGold = 0
                local shareXP = 0
                if deltaGold > 0 then
                    shareGold = deltaGold
                end
                if deltaXP > 0 then
                    shareXP = deltaXP
                end

                -- 如果检测到来源玩家获得了奖励且数值 > 0，则把等量奖励镜像给队友（排除来源玩家本身由配置决定）
                if (shareGold > 0 or shareXP > 0) then
                    -- 使用通用分享函数
                    self:ShareTeamRewardFromPlayer(playerID, shareGold, shareXP, self.TeamShareExcludeKiller)
                end

                -- 更新快照
                self.PlayerGoldSnapshot[playerID] = currentGold
                self.PlayerXPSnapshot[playerID] = xp
            end
        end
    end

    -- 返回下一次调用间隔（秒）
    return 1
end

-- 事件处理示例：实体被击杀时触发的回调
function CAddonPlayerRules:OnEntityKilled(event)
    -- event 通常包含 entindex_killed, entindex_attacker, entindex_inflictor（如果有）等字段
    if event == nil then return end

    local killed_unit = EntIndexToHScript(event.entindex_killed)
    local killer_unit = nil
    if event.entindex_attacker ~= nil then
        killer_unit = EntIndexToHScript(event.entindex_attacker)
    end

    -- 仅在存在被击杀实体时继续
    if killed_unit == nil then return end

    -- 调试信息：打印被击杀和攻击者的名字（如果有）
    local killedName = killed_unit:GetUnitName() or tostring(killed_unit)
    local killerName = "[unknown]"
    if killer_unit ~= nil then killerName = killer_unit:GetUnitName() or tostring(killer_unit) end
    print(string.format("OnEntityKilled: killed=%s killer=%s", killedName, killerName))

    -- 立即镜像：当启用 TeamShareMirror 时，优先根据被击杀单位的原始赏金/经验直接分发给队友
    if self.TeamSharedGoldXP and self.TeamShareMirror and killer_unit ~= nil and killer_unit:IsRealHero() then
        local killerTeam = killer_unit:GetTeamNumber()
        local killedTeam = killed_unit:GetTeamNumber()
        if killedTeam ~= killerTeam then
            local killerPlayerID = nil
            if killer_unit.GetPlayerID then
                killerPlayerID = killer_unit:GetPlayerID()
            end

            if killerPlayerID ~= nil then
                local goldBounty = 0
                if killed_unit.GetGoldBounty then
                    goldBounty = killed_unit:GetGoldBounty()
                end
                local xpBounty = 0
                if killed_unit.GetDeathXP then
                    xpBounty = killed_unit:GetDeathXP()
                end

                if goldBounty > 0 or xpBounty > 0 then
                    -- 直接按被击杀单位应给的金钱/经验镜像给队友（函数内会根据 TeamShareAverage 决定是否平均分配）
                    self:ShareTeamRewardFromPlayer(killerPlayerID, goldBounty, xpBounty, self.TeamShareExcludeKiller)
                    -- 标记来源玩家在下一次采样时忽略由本次击杀产生的本地增长，避免 OnThink 再次镜像
                    self.IgnoreGoldFor[killerPlayerID] = true
                    self.IgnoreXPFor[killerPlayerID] = true
                    print(string.format("OnEntityKilled: mirrored kill bounty %d gold %d xp from player %d", goldBounty, xpBounty, killerPlayerID))
                end
            end
        end
    end

    -- 团队金钱/经验分配逻辑：当启用 TeamSharedGoldXP 且非镜像模式时，使用固定数值分发（否则镜像会在 OnThink 或上面的镜像分发自动处理）
    if self.TeamSharedGoldXP and (not self.TeamShareMirror) and killer_unit ~= nil and killer_unit:IsRealHero() then
        -- 确保不是自杀/队友误伤
        local killerTeam = killer_unit:GetTeamNumber()
        local killedTeam = killed_unit:GetTeamNumber()
        if killedTeam ~= killerTeam then
            local killerPlayerID = nil
            if killer_unit.GetPlayerID then
                killerPlayerID = killer_unit:GetPlayerID()
            end

            -- 使用通用分享函数分发奖励（排除击杀者由配置决定）
            if killerPlayerID ~= nil then
                self:ShareTeamRewardFromPlayer(killerPlayerID, self.TeamShareGoldAmount, self.TeamShareXPAmount, self.TeamShareExcludeKiller)
            end
        end
    end

    -- 自定义第一滴血处理（示例）：如果首次英雄杀死英雄并且我们启用了自定义处理，则记录并打印
    if not self.bFirstBloodHappened and killed_unit and killer_unit then
        if killed_unit:IsRealHero() and killer_unit:IsRealHero() then
            self.bFirstBloodHappened = true
            print("First blood detected: " .. tostring(killerName) .. " killed " .. tostring(killedName))
            -- 在这里你可以添加自定义第一滴血奖励逻辑（例如额外金钱、公告等）
        end
    end

    -- 你可以在此实现更多逻辑：掉落自定义物品、记录击杀数据、添加分数等
end
-- 自定义经验表构建函数
-- 参数：maxLevel -> 要生成到的最大英雄等级
-- 返回：一个 Lua table，索引为等级（从1开始），值为升级所需经验（用于 SetCustomXPRequiredToReachNextLevel）
-- 说明：不同 Dota 2 版本对表的解释可能略有差异，常见用法是将表的第 n 项设为"从等级 n-1 升到 n 所需的经验"。
function CAddonPlayerRules:BuildCustomXPTable(maxLevel)
    local xpTable = {}
    if not maxLevel or maxLevel < 1 then
        return xpTable
    end

    -- 等级1没有经验要求（已在等级1）
    xpTable[1] = 0

    -- 从实例中读取基础参数，若未设置则使用默认值
    local base = self.XPBase or 250
    local growth = self.XPGrowth or 180

    -- 下面使用一个简单的增长公式：
    -- xpForLevel = base * (level-1) + growth * ((level-1)*(level-2)/2)
    -- 这个公式会让每一级增长逐渐增加（近似二次增长），可以根据需要替换成任意序列或手动表
    for lvl = 2, maxLevel do
        local n = lvl - 1
        local xpForLevel = math.floor(base * n + growth * ((n * (n - 1)) / 2))
        xpTable[lvl] = xpForLevel
    end

    return xpTable
end
-- 应用自定义英雄等级上限（如果引擎支持）
    if mode.SetCustomHeroMaxLevel then
        mode:SetCustomHeroMaxLevel(self.MaxHeroLevel)
    end

    -- 构建并应用自定义经验表（如果引擎支持 SetCustomXPRequiredToReachNextLevel）
    if mode.SetCustomXPRequiredToReachNextLevel then
        self.CustomXPTable = self:BuildCustomXPTable(self.MaxHeroLevel)
        -- 打印前几级经验以便调试
        for i = 1, math.min(10, #self.CustomXPTable) do
            -- 注意：表的键从1开始，对应等级
            print(string.format("XP table level %d => %d", i, self.CustomXPTable[i]))
        end
        mode:SetCustomXPRequiredToReachNextLevel(self.CustomXPTable)
        print("Custom XP table applied up to level " .. tostring(self.MaxHeroLevel))
    else
        print("Engine does not support SetCustomXPRequiredToReachNextLevel; skipping custom XP table")
    end
-- 如果你想强制设置最大英雄等级或自定义经验表，请在此实现
    -- 例如：mode:SetCustomHeroMaxLevel(self.MaxHeroLevel)