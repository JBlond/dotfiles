set -g status-bg black
set -g status-fg white

#left
set -g status-left "#[fg=black,bg=colour214] ❐ #S #[fg=colour214,bg=black,nobold,noitalics,nounderscore]"

# right
set -g status-right "#[fg=colour214,bg=black,nobold,noitalics,nounderscore]#[fg=black,bg=colour214]#{?client_prefix,<Prefix> ,}$wg_is_mouse_off  #[fg=brightwhite, bg=colour238] %Y-%m-%d %H:%M "

#### Windows ####
# inactive window
set -g window-status-format "#[fg=black,bg=colour238,nobold,noitalics,nounderscore]#[fg=white,bg=brightblack] #{window_name} #[fg=white,bg=brightblack]#(shell_icons #{pane_current_command}) #[fg=brightblack,bg=black,nobold,noitalics,nounderscore]"

# active window
set -g window-status-current-format "#[fg=black,bg=colour214,nobold,noitalics,nounderscore]#[fg=colour238,bg=colour214] #{window_name} #[fg=brightwhite,bg=colour238] #(shell_icons #{pane_current_command}) #[fg=colour238,bg=black,nobold,noitalics,nounderscore]"

# seperator
set -g window-status-separator ""
