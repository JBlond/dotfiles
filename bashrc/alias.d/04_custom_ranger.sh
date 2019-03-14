if [ -d "$HOME/ranger" ]; then
	alias ranger="$HOME/ranger/ranger.py"
else
	git clone https://github.com/ranger/ranger.git ~/ranger
	~/ranger/ranger.py
fi
