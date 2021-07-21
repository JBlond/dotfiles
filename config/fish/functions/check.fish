function check
    sudo apt update
    sudo apt list --upgradable | column -t | while read -la line
        echo (set_color green --bold)"$line[1]"(set_color normal)\t"$line[2]"\t"$line[6]"
    end | column -t | tr -d "]"
end function
