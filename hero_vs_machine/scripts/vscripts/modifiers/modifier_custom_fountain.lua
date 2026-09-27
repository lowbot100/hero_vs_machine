LinkLuaModifier(
    "modifier_custom_fountain_aura"，
    "modifiers/modifier_custom_fountain.lua"，
    LUA_MODIFIER_MOTION_NONE
)

LinkLuaModifier(
    "modifier_custom_fountain_buff"，
    "modifiers/modifier_custom_fountain.lua"，
    LUA_MODIFIER_MOTION_NONE
)

-- =========================
-- 自定义配置
-- =========================

FountainBuffConfig = FountainBuffConfig or {
    -- 泉水 buff 范围
    Radius = 1200，

    -- 每秒生命恢复（百分比，单位：% 最大生命/秒）
    HealthRegenPercent = 5.0，

    -- 每秒魔法恢复（百分比，单位：% 最大魔法/秒）
    ManaRegenPercent = 6.0，

    -- 是否让英雄在泉水范围内无敌
    Invulnerable = false，

    -- 是否增加状态抗性
    StatusResistance = 0，

    -- 是否增加移动速度（百分比）
    MoveSpeed = 0，
}

-- =========================
-- 泉水范围光环
-- =========================

modifier_custom_fountain_aura = class({})

function modifier_custom_fountain_aura:IsHidden()
    return true
end

function modifier_custom_fountain_aura:IsPurgable()
    return false
end

function modifier_custom_fountain_aura:IsAura()
    return true
end

function modifier_custom_fountain_aura:GetAuraRadius()
    return FountainBuffConfig.Radius
end

function modifier_custom_fountain_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_custom_fountain_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_custom_fountain_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_custom_fountain_aura:GetModifierAura()
    return "modifier_custom_fountain_buff"
end

function modifier_custom_fountain_aura:GetAuraDuration()
    return 0.1
end

-- =========================
-- 英雄获得的泉水 buff（按百分比回复）
-- =========================

modifier_custom_fountain_buff = class({})

function modifier_custom_fountain_buff:IsHidden()
    return false
end

function modifier_custom_fountain_buff:IsPurgable()
    return false
end

function modifier_custom_fountain_buff:RemoveOnDeath()
    return true
end

function modifier_custom_fountain_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_custom_fountain_buff:GetModifierStatusResistanceStacking()
    return FountainBuffConfig.StatusResistance or 0
end

function modifier_custom_fountain_buff:GetModifierMoveSpeedBonus_Percentage()
    return FountainBuffConfig.MoveSpeed or 0
end

-- 使用定时器每秒按百分比恢复生命与魔法
function modifier_custom_fountain_buff:OnCreated(kv)
    if IsServer() then
        self.health_pct = FountainBuffConfig.HealthRegenPercent or 0
        self.mana_pct = FountainBuffConfig.ManaRegenPercent or 0
        -- 每秒触发一次回复
        self:StartIntervalThink(1.0)
    end
end

function modifier_custom_fountain_buff:OnDestroy()
    if IsServer() then
        -- 停止定时器
        self:StartIntervalThink(-1)
    end
end

function modifier_custom_fountain_buff:OnIntervalThink()
    if not IsServer() then return end

    local parent = self:GetParent()
    if not parent or parent:IsNull() then return end

    -- 计算并应用生命回复（按最大生命的百分比）
    if self.health_pct and self.health_pct > 0 then
        local max_hp = parent:GetMaxHealth()
        if max_hp and max_hp > 0 then
            local hp_add = max_hp * (self.health_pct / 100)
            if hp_add > 0 then
                parent:Heal(hp_add, nil)
            end
        end
    end

    -- 计算并应用魔法回复（按最大魔法的百分比）
    if self.mana_pct and self.mana_pct > 0 then
        local max_mana = parent:GetMaxMana()
        if max_mana and max_mana > 0 then
            local mana_add = max_mana * (self.mana_pct / 100)
            if mana_add > 0 then
                parent:GiveMana(mana_add)
            end
        end
    end
end

function modifier_custom_fountain_buff:CheckState()
    if FountainBuffConfig.Invulnerable then
        return {
            [MODIFIER_STATE_INVULNERABLE] = true,
        }
    end

    return {}
end

-- =========================
-- 给所有地图泉水添加自定义光环
-- =========================

function ApplyCustomFountainBuffs()
    local fountain = Entities:FindByClassname(nil, "ent_dota_fountain")

    while fountain do
        if not fountain:IsNull() then
            if not fountain:HasModifier("modifier_custom_fountain_aura") then
                fountain:AddNewModifier(
                    fountain,
                    nil,
                    "modifier_custom_fountain_aura",
                    {}
                )

                print(
                    "[FountainBuff] Applied to fountain, team:",
                    fountain:GetTeamNumber()
                )
            end
        end

        fountain = Entities:FindByClassname(
            fountain,
            "ent_dota_fountain"
        )
    end
end