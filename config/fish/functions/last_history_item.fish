function last_history_item --description 'Get last command'
    echo $history[1]
end
abbr -a !! --position anywhere --function last_history_item --quiet
