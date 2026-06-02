function ':e' --description 'Alias :e to nvim or vim'
    if type -q nvim
        command nvim $argv
    else
        command vim $argv
    end
end
