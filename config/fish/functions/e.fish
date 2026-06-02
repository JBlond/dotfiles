function :e --description 'Alias :e to nvim if available, otherwise to vim'
    if type -q nvim
        command nvim $argv
    else
        command vim $argv
    end
end
