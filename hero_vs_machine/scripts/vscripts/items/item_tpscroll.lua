if item_tpscroll == nil then
    item_tpscroll = class({})
end

function item_tpscroll:OnSpellStart()
    local caster = self:GetCaster()
    if not caster or caster:IsNull() then return end

    local fountain = nil
    local entity = Entities:FindByClassname(nil, "ent_dota_fountain")
    while entity do
        if entity:GetTeamNumber() == caster:GetTeam() then
            fountain = entity
            break
        end
        entity = Entities:FindByClassname(entity, "ent_dota_fountain")
    end

    if not fountain then
        print("[item_tpscroll] No team fountain found")
        return
    end

    local particle = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_teleport/teleport_start.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        caster
    )
    ParticleManager:ReleaseParticleIndex(particle)
    EmitSoundOn("Hero_Tinker.TeleportOut", caster)

    FindClearSpaceForUnit(caster, fountain:GetAbsOrigin(), true)

    local arrivalParticle = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_teleport/teleport_end.vpcf",
        PATTACH_ABSORIGIN_FOLLOW,
        caster
    )
    ParticleManager:ReleaseParticleIndex(arrivalParticle)
    EmitSoundOn("Hero_Tinker.TeleportIn", caster)
end
