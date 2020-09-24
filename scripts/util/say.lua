return function(msg)
    if ThePlayer and ThePlayer.components.talker then
        ThePlayer.components.talker:Say(msg)
    end
end
