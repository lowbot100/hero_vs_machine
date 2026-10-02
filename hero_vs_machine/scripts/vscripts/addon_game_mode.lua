require('gamerules')
require('goldandxp')

if CAddonPlayerRules == nil then
   CAddonPlayerRules = class({})
end



-- Activate 在自定义游戏启动时被引导调用，创建并初始化我们的规则实例
function Activate()
    -- 存在 GameRules 的字段中以便调试时能方便访问
    GameRules.Addon = CAddonPlayerRules()
    GameRules.Addon:InitGameMode()
end

-- 初始化游戏模式：设置各种自定义规则和定时器
function CAddonPlayerRules:InitGameMode()
    print("Addon is loaded.")

    -- 是否允许相同英雄重复选择（true = 允许，false = 不允许）
    self.AllowSameHero = false 

    -- 游戏平衡变量（倍率类）
    self.CreepGoldMultiplier = 1.0   -- 小兵金钱倍率（其他系统可读取并应用）
    self.CreepXPMultiplier = 1.0     -- 小兵经验倍率
    self.TowerDamageMultiplier = 1.0  -- 防御塔伤害倍率（需在塔的脚本中使用此值进行调整）

    -- Buyback（回购）相关（有些引擎方法可能不存在，仅作为配置供其他脚本使用）
    self.EnableBuyback = true
    self.BuybackCostPercent = 100     -- 回购消耗金钱的百分比（示例配置，具体应用需在脚本中实现）
    self.BuybackCooldown = 300        -- 回购冷却时间（秒）

    -- 中立物品/掉落相关
    self.EnableNeutralItems = true
    self.NeutralItemDropRate = 1.0    -- 掉率倍率，1 = 正常

    -- 其他可调变量（供自定义脚本读取）
    self.EnableCustomAnnouncer = false
    self.EnableShopSharing = false

    -- 内部状态：记录第一滴血是否已经发生（用于自定义处理）
    self.bFirstBloodHappened = false

    -- 注册事件监听器：在实体被击杀、游戏状态变化、玩家连接/断开时做处理
    ListenToGameEvent("entity_killed", Dynamic_Wrap(self, "OnEntityKilled"), self)
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(self, "OnGameRulesStateChange"), self)
    ListenToGameEvent("player_disconnect", Dynamic_Wrap(self, "OnPlayerDisconnect"), self)

    -- 如果需要允许相同英雄复选/随机选择，可以在这里设置（示例为注释）
    -- if mode.SetAllowSameHeroSelection ~= nil then
    --     mode:SetAllowSameHeroSelection(self.AllowSameHero)
    -- end

    -- 尝试应用其他可用的引擎/模式设置（存在性检查）
    if mode.SetBuybackEnabled then
        mode:SetBuybackEnabled(self.EnableBuyback)
    else
        print("Mode does not support SetBuybackEnabled; set EnableBuyback is just a config value")
    end

    if mode.SetBuybackCooldown then
        mode:SetBuybackCooldown(self.BuybackCooldown)
    end

    if mode.SetCreepGoldMultiplier then
        mode:SetCreepGoldMultiplier(self.CreepGoldMultiplier)
    else
        -- 若引擎没有直接接口，你可以在小兵死亡事件中手动应用此倍率
        print("Mode does not support SetCreepGoldMultiplier; use CreepGoldMultiplier in your creep death handler")
    end

    if mode.SetCreepXPMultiplier then
        mode:SetCreepXPMultiplier(self.CreepXPMultiplier)
    end
    
end



-- 游戏状态变化回调示例
function CAddonPlayerRules:OnGameRulesStateChange(event)
    -- 注意：不同环境下，获取具体状态的方式可能不同。
    -- 这里仅做简单的日志记录供调试使用。
    print("GameRules state changed")
    -- 如果你需要更细粒度的处理，可以查询 GameRules:State_Get()（若可用），或使用定时器延迟获取实体
end

-- 玩家断开连接回调示例
function CAddonPlayerRules:OnPlayerDisconnect(event)
    -- event 通常包含 PlayerID / userid 等字段
    print("OnPlayerDisconnect event:")
    -- 如果需要进一步处理，可以使用 event.player_id 或 event.userid（视具体事件结构而定）
    -- PrintTable(event)  -- 开发时可启用以查看完整事件字段
end

-- 示例：如何在类里定义一个其它事件处理函数（取消注释并根据需要实现）
-- function CAddonPlayerRules:OnSomeOtherEvent(event)
--     -- 处理逻辑
-- end

require ('barracks')
