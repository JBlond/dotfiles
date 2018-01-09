# Update window size after every command
shopt -s checkwinsize

# No more needless typing of the cd command. Just type the directory path and bash will cd into it.
shopt -s autocd

# Perform file completion in a case insensitive fashion
bind "set completion-ignore-case on"

# Immediately add a trailing slash when autocompleting symlinks to directories
bind "set mark-symlinked-directories on"
