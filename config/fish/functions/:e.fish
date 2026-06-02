function :e
    if type -q nvim
        command nvim $argv
    else
        command vim $argv
    end
end
