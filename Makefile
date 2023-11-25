.DEFAULT_GOAL := help

##help: Shows this list
.PHONY: help
help:
	@grep -E '\#\#[a-zA-Z\.\-]+:.*$$' $(MAKEFILE_LIST) \
		| tr -d '##' \
		| awk 'BEGIN {FS = ": "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' \

##backup: take a backup of the original .bashrc (it is saved as .bashrc.ORIGINAL)
.PHONY: backup
backup:
	@test -f $(HOME)/.bashrc.ORIGINAL && echo "Backup already exists!" || echo -n ""
	@test ! -f $(HOME)/.bashrc || cp $(HOME)/.bashrc $(HOME)/.bashrc.ORIGINAL

##cert: stop apache and updte let's encrypt
.PHONY: cert
cert:
	@./scripts/update_cert.sh


##install: run the deploy script
.PHONY: install
install:
	@./scripts/deploy.sh
	@git submodule update --init --recursive

##update: update source with the last version from github and deploy it.
.PHONY: update
update:
	@git pull origin main
	@make install
	@git pull --recurse-submodules

##fonts: install emojis for fonts
.PHONY: fonts
fonts:
	@./scripts/fonts.sh

##apt: install fish tmux vim via apt
.PHONY: apt
apt:
	@echo ""
	@sudo apt install fish tmux vim

##pacman: install fish tmux vim via pacman
.PHONY: pacman
pacman:
	@echo ""
	@pacman -S fish tmux
