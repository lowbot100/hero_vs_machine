function initplayerstats()
    PlayerStats={}
    --[[playerid=0
        ...
        playerid=9
      ]]
      for i=0,9 do
        PlayerStats[i]={}
        PlayerStats[i]['kaishi']=0
      end

    --初始化刷怪
    local zuoshang=Entity:FindByName(handle_1, string_2)
end