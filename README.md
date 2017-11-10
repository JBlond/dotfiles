# dotfiles
just my dot files

```bash
git clone https://github.com/JBlond/dotfiles.git
cd dotfiles
./deploy.sh
```

# scripts

- agent.sh start ssh agent with keys
- aliases.sh a bunch from my favorite bash aliases including fuck command if I forgot to type *sudo* infront of a command
- bash_completion.sh execute all bash completion available default from the system
- complete_ssh_hosts.sh ssh example *TAB* reads the ~/.ssh/config file for host completion
- debug.sh run a bash script in debug mode
- deploy.sh deploy these files
- diff-so-fancy fancy diff for git ( and others)
- _docker.sh docker aliases + ssh into docker / docker exec completion. e.g. dssh example *TAB*
- functions.sh wgets wget with Firefox header. extract for many archive formats
- git_functions.sh part for simplify git.  an = add next git file dn = diff next file
- git-prompt.sh have a nice prompt inside git repos

```
jblond@linux:~/dotfiles
(master) ✓
λ git commit -a -m "my commit" 
```

- ✓ = repo is clean
- nx🙈  = n untracked files
- nxΞ = n added files
- nx● = n modified files
- nxᏪ = n renamed files
- nx✗ = n deleted files
- ▲n = n steps ahead of remote
- ▼n = n steps behind remote
 
