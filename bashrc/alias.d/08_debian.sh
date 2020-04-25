#debian
alias update='sudo apt update'
alias list='sudo apt list --upgradable'
alias upgrade='sudo apt dist-upgrade'
alias autoremove='sudo apt autoremove'
alias install='sudo apt install'

alias journalctl='sudo journalctl'
alias systemctl='sudo systemctl'
alias sc='systemctl'

# Get and display the distribution type. (original base first)
if [ -f /etc/os-release -a -r /etc/os-release ]; then
	alias distro='\
		while read -a X; do
			if [[ "${X[0]}" == ID_LIKE=* ]]; then
				echo "${X[0]/*=}"; break
			elif [[ "${X[0]}" == ID=* ]]; then
				echo "${X[0]/*=}"; break
			fi
		done < /etc/os-release
	'
fi
