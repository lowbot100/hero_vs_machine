function npc_dota_creep_lv1_spa()
    for i = 1,3 do
    GameRules:CreateUnitByName(npc_dota_creep_lv1, Vector_2, bool_3, handle_4, handle_5, DOTA_TEAM_GOODGUYS)
    end

    return 30
end