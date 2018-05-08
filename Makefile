help:
	@echo  "  make backup		take a backup of the original .bashrc"
	@echo  "                        (it is saved as .bashrc.ORIGINAL)"
	@echo  "                        you should run this once in the begining"
	@echo  "                        otherwise you may overwrite the backup"
	@echo  " make install		run the deploy script"

backup:
	@test -f $(HOME)/.bashrc.ORIGINAL && echo "Backup already exists!" || echo -n ""
	@test ! -f $(HOME)/.bashrc || cp $(HOME)/.bashrc $(HOME)/.bashrc.ORIGINAL

install:
	@./deploy.sh
