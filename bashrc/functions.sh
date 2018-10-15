function wgets() {
	local H='--header'
	wget $H='Accept-Language: en-us,en;q=0.5' $H='Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' $H='Connection: keep-alive' -U ' Mozilla/5.0 (Windows NT 10.0; WOW64; rv:48.0) Gecko/20100101 Firefox/48.0' --referer=/ "$@";
}

extract () {
	if [ -f $1 ] ; then
		case $1 in
			*.tar.bz2)   tar xvfj $1    ;;
			*.tar.gz)    tar xvfz $1    ;;
			*.bz2)       bunzip2 $1     ;;
			*.rar)       unrar x $1     ;;
			*.gz)        gunzip $1      ;;
			*.tar)       tar xvf $1     ;;
			*.tbz2)      tar xvfj $1    ;;
			*.tgz)       tar xvfz $1    ;;
			*.zip)       unzip $1       ;;
			*.Z)         uncompress $1  ;;
			*.7z)        7z x $1        ;;
			*)           echo "don't know how to extract '$1'..." ;;
		esac
	else
		echo "'$1' is not a valid file!"
	fi
}

matrix () {
	echo -e "\e[1;40m"; 
	clear;
	while :;
	do
		echo $LINES $COLUMNS $(( $RANDOM % $COLUMNS)) $(( $RANDOM % 72 ));
		sleep 0.05; 
	done|awk '{ letters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()"; c=$4; letter=substr(letters,c,1);a[$3]=0;for (x in a) {o=a[x];a[x]=a[x]+1; printf "\033[%s;%sH\033[2;32m%s",o,x,letter; printf "\033[%s;%sH\033[1;37m%s\033[0;0H",a[x],x,letter;if (a[x] >= $1) { a[x]=0; } }}'
}

# check processes using a port
function port() {
	lsof -iTCP:$1 -sTCP:LISTEN
}

# find shorthand
function f() {
	find . -name "$1" 2>&1 | grep -v 'Permission denied'
}

function rns() {
	grep -Rins $1 *
}


logbook() {
	echo "" >>  ~/logs/logbook
	printf '%s' "--------------------------------------------------------------------------------" >> ~/logs/logbook
	echo "" >>  ~/logs/logbook
	date >> ~/logs/logbook
	printf '%s' "--------------------------------------------------------------------------------" >> ~/logs/logbook
	echo "" >>  ~/logs/logbook
	printf '%s' "$1" >> ~/logs/logbook
	echo "" >>  ~/logs/logbook
	cd ~/logs/
	git commit -a -m "logbook" && git push;
}

foodbook() {
	echo "" >>  ~/logs/foodbook
	printf '%s' "--------------------------------------------------------------------------------" >> ~/logs/foodbook
	echo "" >>  ~/logs/foodbook
	date >> ~/logs/foodbook
	printf '%s' "--------------------------------------------------------------------------------" >> ~/logs/foodbook
	echo "" >>  ~/logs/foodbook
	printf '%s' "$1" >> ~/logs/foodbook
	echo "" >>  ~/logs/foodbook
	cd ~/logs/
	git commit -a -m "foodbook" && git push;
}

function install-phpmyadmin() {
	git clone --depth 1 -b STABLE https://github.com/phpmyadmin/phpmyadmin.git
	cd phpmyadmin
	composer install
	mkdir -p locale/de/LC_MESSAGES
	msgfmt po/de.po -o locale/de/LC_MESSAGES/phpmyadmin.mo
}

function bash_stats() {
	fc -l 1 | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl |  head -n20
}

function sst()  {
	ssh -t $@ "tmux attach || tmux";
}