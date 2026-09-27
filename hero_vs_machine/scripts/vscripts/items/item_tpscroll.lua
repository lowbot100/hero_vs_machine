if item_tpscroll == nil then
    item_tpscroll = class({})
end

-- 通道开始：记录目标位置/单位并播启动特效（通道期间玩家可被打断）
function item_tpscroll:OnSpellStart()
    if not IsServer() then return end
    local caster = self:GetCaster()
    if not caster or caster:IsNull() then return end

    -- 保存目标（优先单位，其次点位；若都没选则回退喷泉）
    local targetUnit = self:GetCursorTarget()
    local targetPos = nil
    if targetUnit and not targetUnit:IsNull() then
        targetPos = targetUnit:GetAbsOrigin()
    else
        targetPos = self:GetCursorPosition()
    end

    -- 如果没有有效位置（玩家直接回车或没选），退回喷泉
    if not targetPos or targetPos == Vector(0,0,0) then
        local fountain = nil
        local entity = Entities:FindByClassname(nil, "ent_dota_fountain")
        while entity do
            if entity:GetTeamNumber() == caster:GetTeamNumber() then
                fountain = entity
                break
            end
            entity = Entities:FindByClassname(entity, "ent_dota_fountain")
        end
        if fountain then
            targetPos = fountain:GetAbsOrigin()
        else
            print("[item_tpscroll] No team fountain found for team", caster:GetTeamNumber())
            return
        end
    end

    -- 把目标位置保存在 ability 上，供 OnChannelFinish 使用
    self._tpscroll_target = targetPos

    -- 播开始通道的特效（仅视觉/音效）
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_teleport/teleport_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:ReleaseParticleIndex(particle)
    EmitSoundOn("Hero_Tinker.TeleportOut", caster)

    -- 注意：通道的真实完成由引擎调用 OnChannelFinish(bInterrupted)
end

-- 通道结束回调：若未被打断则执行传送逻辑；并确保物品不会被永久消耗，设置冷却
function item_tpscroll:OnChannelFinish(bInterrupted)
    if not IsServer() then return end
    local caster = self:GetCaster()
    if not caster or caster:IsNull() then return end

    -- 取消通道（被打断）则播放取消音效并返回
    if bInterrupted then
        EmitSoundOn("DOTA_Item.TPScroll.Cancel", caster)
        return
    end

    local targetPos = nil
    if self._tpscroll_target and type(self._tpscroll_target) == "table" then
        targetPos = self._tpscroll_target
    else
        targetPos = caster:GetAbsOrigin()
    end

    -- 防止和建筑/喷泉中心重合导致卡住，轻微偏移
    targetPos = targetPos + RandomVector(50)

    -- 传送特效与声音
    local arrivalParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_teleport/teleport_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:ReleaseParticleIndex(arrivalParticle)
    EmitSoundOn("Hero_Tinker.TeleportIn", caster)

    FindClearSpaceForUnit(caster, targetPos, true)
    -- 解除眩晕/停顿/设置朝向可在此处补充

    -- 确保传送卷轴不会被消耗：
    -- 引擎可能会在 OnChannelFinish 之前把物品移除（消耗），所以这里检查背包是否还有同名物品，
    -- 若没有则重新创建一个并添加到背包，同时把它设置为当前冷却（10s）。
    local existing_item = nil
    for i = 0, 5 do
        local it = caster:GetItemInSlot(i)
        if it and it:GetName() == "item_tpscroll" then
            existing_item = it
            break
        end
    end

    local COOLDOWN = 10.0
    if not existing_item then
        local newItem = CreateItem("item_tpscroll", caster, caster)
        caster:AddItem(newItem)
        -- 把新物品马上设置为冷却，避免瞬间重复使用
        if newItem.StartCooldown then
            newItem:StartCooldown(COOLDOWN)
        end
    else
        -- 如果物品仍在背包，确保它进入冷却
        if existing_item.StartCooldown then
            existing_item:StartCooldown(COOLDOWN)
        end
    end

    -- 如果你想让物品按技能的冷却（比如考虑减冷效果等），可以改成：
    -- local cd = self:GetCooldownTimeRemaining() or COOLDOWN
    -- existing_item:StartCooldown(cd)
end