help:
	@echo " make backup        take a backup of the original .bashrc"
	@echo "                    (it is saved as .bashrc.ORIGINAL)"
	@echo "                    you should run this once in the begining"
	@echo "                    otherwise you may overwrite the backup"
	@echo ""
	@echo " make cert          stop apache and updte let's encrypt"
	@echo ""
	@echo " make install       run the deploy script"
	@echo ""
	@echo " make update        update source with the last version from github"
	@echo ""

backup:
	@test -f $(HOME)/.bashrc.ORIGINAL && echo "Backup already exists!" || echo -n ""
	@test ! -f $(HOME)/.bashrc || cp $(HOME)/.bashrc $(HOME)/.bashrc.ORIGINAL

cert:
	@./update_cert.sh

install:
	@./deploy.sh
	@git submodule update --init --recursive

update:
	@git pull origin main
	@git pull --recurse-submodules
	@make install
