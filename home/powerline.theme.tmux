set -wg window-status-separator ""

#left 
set -g status-left "#[fg=black,bg=colour214] ❐ #S #[fg=black,bg=colour214][#I:#P]#[fg=colour214,bg=colour238,nobold,noitalics,nounderscore]"

# default inactive window
set-window-option -g window-status-format '#[fg=colour214,bg=colour238] #I #[fg=white,bg=colour238] #W#[fg=colour238,bg=colour238,nobold,noitalics,nounderscore]'

# current window
set-window-option -g window-status-current-format '#[fg=colour238,bg=colour214,nobold,noitalics,nounderscore]#[fg=colour238,bg=colour214] #I #[fg=colour214,bg=colour238,nobold,noitalics,nounderscore]#[fg=brightwhite,bg=colour238] #W#[fg=colour238,bg=colour238,nobold,noitalics,nounderscore]'

# right
set -g status-right "#[fg=colour214,bg=black,nobold,noitalics,nounderscore]#[fg=black,bg=colour214] Date #[fg=brightwhite, bg=colour238] %Y-%m-%d %H:%M "
