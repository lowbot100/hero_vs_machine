LinkLuaModifier("modifier_item_null_talisman_plus", "items/item_null_talisman_plus.lua", LUA_MODIFIER_MOTION_NONE)

if item_null_talisman_plus == nil then item_null_talisman_plus = class({}) end
function item_null_talisman_plus:GetIntrinsicModifierName()
    return "modifier_item_null_talisman_plus"
end

if modifier_item_null_talisman_plus == nil then modifier_item_null_talisman_plus = class({}) end
function modifier_item_null_talisman_plus:IsHidden() return true end
function modifier_item_null_talisman_plus:IsPurgable() return false end
function modifier_item_null_talisman_plus:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_item_null_talisman_plus:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    }
end

-- Use a dynamic calculation so the bonus scales with the unit's current max mana
function modifier_item_null_talisman_plus:GetModifierBonusStats_Intellect()
    return 30
end
function modifier_item_null_talisman_plus:GetModifierBonusStats_Strength()
    return 12
end
function modifier_item_null_talisman_plus:GetModifierBonusStats_Agility()
    return 12
end
function modifier_item_null_talisman_plus:GetModifierManaBonus()
    local parent = self:GetParent()
    if parent then
        local maxMana = parent:GetMaxMana() or 0
        return math.floor(maxMana * 0.18)
    end
    return 0
end
function modifier_item_null_talisman_plus:GetModifierConstantManaRegen()
    return 6
end
