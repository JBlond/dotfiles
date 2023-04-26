function zfs
    switch $argv[1]
        case destory
            set argv[1] destroy
    end
    command zfs $argv
end