-- =====================
    -- 可调节的游戏规则（开发者可根据需要修改）
    -- 在这里添加/修改变量即可快速调整游戏体验
    -- =====================

    -- 玩家队伍最大人数设置（天辉/夜魇）
    -- 如果你想要更少或更多玩家，修改下面两个值
    self.iDesiredRadiant = 10
    self.iDesiredDire = 0

    -- 自定义游戏离开是否安全：
    -- false = 启用离开惩罚（不安全离开会被计入）、true = 不启用惩罚
    self.SafeToLeave = true

    -- 死亡是否掉落金钱：false = 不掉落，true = 掉落
    self.GOLDLOSS = false

    -- 是否启用第一滴血奖励（引擎层级）
    self.FirstBlood = false

    -- 玩家初始金钱（出生时得到的金钱）
    self.StartingGold = 5000

    -- 金钱每次滴答奖励数目（每次加多少）
    self.GoldPer = 1

    -- 金钱滴答时间间隔（秒）
    self.GoldTick = 0.6

    -- 英雄选择时间（秒）
    self.HeroSelectionTime = 60

    -- 树木从被摧毁到重生所需的秒数
    self.TreeRegrowTime = 60

    -- 英雄复活/重生控制
    self.AllowHeroRespawn = true      -- 是否允许英雄复活（若你要做无复活模式，设为 false 并在相应事件中阻止复活）
    self.FixedRespawnTime = nil       -- 如果想设固定复活时间（秒），设为数字即可；nil 表示使用默认缩放

    -- 额外规则示例（仅变量，不直接修改核心引擎行为，可根据需要启用）
    self.PreGameTime = 30         -- 正式开始前的准备时间
    self.StrategyTime = 0         -- 策略选择时间（部分模式使用）
    self.PostGameTime = 60        -- 结束后显示时间

-- =====================
-- 结束初始化
print("Game rules initialized:",
          "Radiant=" .. tostring(self.iDesiredRadiant),
          "Dire=" .. tostring(self.iDesiredDire),
          "StartingGold=" .. tostring(self.StartingGold))
-- =====================
    -- 将配置应用到 Dota2 引擎/模式实体上（尽量使用存在性检查）
    -- =====================
function CAddonAllGameRules:InitGameMode()
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, self.iDesiredRadiant)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, self.iDesiredDire)

    local mode = GameRules:GetGameModeEntity()

    -- 把 OnThink 注册到游戏主循环，每隔 1 秒进行一次检查（包含共享检测）
    -- 注意：SetThink 可以接受方法名和 self（字符串方式）或直接传入函数。
    mode:SetThink("OnThink", self, "GlobalThink", 1)

    -- 设置死亡是否掉落金钱
    GameRules:GetGameModeEntity():SetLoseGoldOnDeath(self.GOLDLOSS)

    -- 设置是否允许安全离开
    GameRules:SetSafeToLeave(self.SafeToLeave)

    -- 设置第一滴血开关
    GameRules:SetFirstBloodActive(self.FirstBlood)

    -- 设置玩家起始金钱
    GameRules:SetStartingGold(self.StartingGold)

    -- 金钱滴答相关设置
    GameRules:SetGoldPerTick(self.GoldPer)
    GameRules:SetGoldTickTime(self.GoldTick)

    -- 英雄选择及树木重生时间
    GameRules:SetHeroSelectionTime(self.HeroSelectionTime)
    GameRules:SetTreeRegrowTime(self.TreeRegrowTime)

    -- 额外时间设置（引擎支持时生效）
    -- 注意：下面函数在不同的 Dota 2 版本/环境中可能不同，若不存在请注释或移除
    if GameRules.SetPreGameTime then
        GameRules:SetPreGameTime(self.PreGameTime)
    end
    if GameRules.SetStrategyTime then
        GameRules:SetStrategyTime(self.StrategyTime)
    end
    if GameRules.SetPostGameTime then
        GameRules:SetPostGameTime(self.PostGameTime)
    end
end
    