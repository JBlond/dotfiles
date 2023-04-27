function zfs
    switch $argv[1]
        case destory
            set argv[1] destroy
        case ls
             set argv[1] list -t snapshot
    end
    command zfs $argv
end