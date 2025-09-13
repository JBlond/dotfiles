if test -d $HOME/ranger
	alias ranger="$HOME/ranger/ranger.py"
end
alias :D="echo ツ"
if command -sq nvim
    alias :e="nvim"
else
    alias :e="vim"
end
# use vim alias to exit shell
alias :q="exit"

alias vless "/usr/share/vim/vim9*/macros/less.sh"
