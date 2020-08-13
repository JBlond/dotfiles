set -wg window-status-separator ""

#left 
set -g status-left "#[fg=black,bg=colour214] ❐ #S #[fg=black,bg=colour214][#I:#P]#[fg=colour214,bg=colour238]"

# default inactive window
set-window-option -g window-status-format '#[fg=colour214,bg=colour238] #I #[fg=white,bg=colour238] #W '

# current window
set-window-option -g window-status-current-style none
set-window-option -g window-status-current-format '#[fg=colour238,bg=colour214]#[fg=colour238,bg=colour214] #I #[fg=colour214,bg=colour238]#[fg=brightwhite,bg=colour238] #W'
