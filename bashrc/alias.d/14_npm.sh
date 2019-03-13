alias npm-clean="npm ls -p --depth=0 | awk -F/ '/node_modules/ && !/\/npm$/ {print $NF}' | xargs npm rm"
alias npm-clean-global="npm ls -gp --depth=0 | awk -F/ '/node_modules/ && !/\/npm$/ {print $NF}' | xargs npm -g rm"
