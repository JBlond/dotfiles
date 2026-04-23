function nvim
    if not command -sq nvim
        echo "nvim nicht gefunden"
        return 127
    end

    command nvim $argv
    set exit_code $status

    # only interaktiv + real Terminal
    if status is-interactive
        if test -t 1
            if set -q TERM_PROGRAM; and string match -q "*mintty*" $TERM_PROGRAM
                printf '\e[3 q'
            end
        end
    end
    return $exit_code
end