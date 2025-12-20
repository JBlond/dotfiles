function fish_colors --on-event fish_prompt
    set -g fish_color_autosuggestion 555 --background=brblack
    set -g fish_color_cancel -r
    set -g fish_color_command 005fd7
    set -g fish_color_comment 990000
    set -g fish_color_cwd green
    set -g fish_color_cwd_root red
    set -g fish_color_end 009900
    set -g fish_color_error ff0000
    set -g fish_color_escape 00a6b2
    set -g fish_color_history_current --bold
    set -g fish_color_host normal
    set -g fish_color_match --background=brblue
    set -g fish_color_normal normal
    set -g fish_color_operator 00a6b2
    set -g fish_color_param 00afff
    set -g fish_color_quote 999900
    set -g fish_color_redirection 00afff

    set -g fish_color_search_match bryellow --background=brblack
    set -g fish_color_selection white --bold --background=brblack

    set -g fish_color_user brgreen
    set -g fish_color_valid_path --underline
end
