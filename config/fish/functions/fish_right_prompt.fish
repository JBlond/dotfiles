function _cmd_duration -S -d 'Show command duration'

    if [ "$CMD_DURATION" -lt 500 ]
        echo -ns $CMD_DURATION 'ms'
        and return
    end

    humantime $CMD_DURATION

    set_color $fish_color_normal
    set_color $fish_color_autosuggestion
end

# from https://github.com/jorgebucaran/humantime.fish
function humantime --argument-names ms --description "Turn milliseconds into a human-readable string"
    set --query ms[1] || return

    set --local secs (math --scale=1 $ms/1000 % 60)
    set --local mins (math --scale=0 $ms/60000 % 60)
    set --local hours (math --scale=0 $ms/3600000)

    test $hours -gt 0 && set --local --append out $hours"h"
    test $mins -gt 0 && set --local --append out $mins"m"
    test $secs -gt 0 && set --local --append out $secs"s"

    set --query out && echo $out || echo $ms"ms"
end

function fish_right_prompt -d 'is all about the right prompt'
    set -l h_left_arrow_glyph \uE0B3
    if [ "$theme_powerline_fonts" = "no" ]
        set _left_arrow_glyph '<'
    end

    set_color $fish_color_autosuggestion

    _cmd_duration
    echo ' ['
    date '+%H:%M'
    echo ']'
    set_color normal
end
