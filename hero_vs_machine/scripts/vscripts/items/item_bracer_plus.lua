LinkLuaModifier("modifier_item_bracer_plus", "items/item_bracer_plus.lua", LUA_MODIFIER_MOTION_NONE)

if item_bracer_plus == nil then item_bracer_plus = class({}) end
function item_bracer_plus:GetIntrinsicModifierName()
    return "modifier_item_bracer_plus"
end

if modifier_item_bracer_plus == nil then modifier_item_bracer_plus = class({}) end
function modifier_item_bracer_plus:IsHidden() return true end
function modifier_item_bracer_plus:IsPurgable() return false end
function modifier_item_bracer_plus:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_item_bracer_plus:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_HEALTH_BONUS,
    }
end

function modifier_item_bracer_plus:GetModifierBonusStats_Strength()
    return 30
end
function modifier_item_bracer_plus:GetModifierBonusStats_Agility()
    return 12
end
function modifier_item_bracer_plus:GetModifierBonusStats_Intellect()
    return 12
end
function modifier_item_bracer_plus:GetModifierPreAttack_BonusDamage()
    return 0
end
function modifier_item_bracer_plus:GetModifierConstantHealthRegen()
    return 4.5
end
function modifier_item_bracer_plus:GetModifierHealthBonus()
    return 30
end
