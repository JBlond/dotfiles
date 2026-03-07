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

alias ansible 'docker run -ti --rm \
  -v ~/.ssh:/mnt/ssh \
  -v (pwd):/apps \
  -w /apps \
  --network host \
  alpine/ansible sh -c "mkdir -p /root/.ssh && cp -r /mnt/ssh/* /root/.ssh/ && chmod 700 /root/.ssh && chmod 600 /root/.ssh/* && exec ansible $argv"'

alias ansible-playbook 'docker run -ti --rm \
  -v ~/.ssh:/mnt/ssh \
  -v (pwd):/apps \
  -w /apps \
  --network host \
  alpine/ansible sh -c "mkdir -p /root/.ssh && cp -r /mnt/ssh/* /root/.ssh/ && chmod 700 /root/.ssh && chmod 600 /root/.ssh/* && exec ansible-playbook $argv"'
