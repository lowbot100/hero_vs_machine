LinkLuaModifier("modifier_item_wraith_band_plus", "items/item_wraith_band_plus.lua", LUA_MODIFIER_MOTION_NONE)

if item_wraith_band_plus == nil then item_wraith_band_plus = class({}) end
function item_wraith_band_plus:GetIntrinsicModifierName()
    return "modifier_item_wraith_band_plus"
end

if modifier_item_wraith_band_plus == nil then modifier_item_wraith_band_plus = class({}) end
function modifier_item_wraith_band_plus:IsHidden() return true end
function modifier_item_wraith_band_plus:IsPurgable() return false end
function modifier_item_wraith_band_plus:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_item_wraith_band_plus:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }
end

function modifier_item_wraith_band_plus:GetModifierBonusStats_Agility()
    return 30
end
function modifier_item_wraith_band_plus:GetModifierBonusStats_Strength()
    return 12
end
function modifier_item_wraith_band_plus:GetModifierBonusStats_Intellect()
    return 12
end
function modifier_item_wraith_band_plus:GetModifierAttackSpeedBonus_Constant()
    return 36
end
function modifier_item_wraith_band_plus:GetModifierPhysicalArmorBonus()
    return 10.5
end
