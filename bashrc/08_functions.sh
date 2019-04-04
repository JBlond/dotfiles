# Make file executable, then run it
run() {
	chmod +x "$1"
	exec "./$1" &
}

function wgets() {
	local H='--header'
	wget $H='Accept-Language: en-us,en;q=0.5' $H='Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' $H='Connection: keep-alive' -U ' Mozilla/5.0 (Windows NT 10.0; WOW64; rv:48.0) Gecko/20100101 Firefox/48.0' --referer=/ "$@";
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


function install-phpmyadmin() {
	git clone --depth 1 -b STABLE https://github.com/phpmyadmin/phpmyadmin.git
	cd phpmyadmin
	composer install
	mkdir -p locale/de/LC_MESSAGES
	msgfmt po/de.po -o locale/de/LC_MESSAGES/phpmyadmin.mo
}

function mk() {
	mkdir -p "$@" && cd "$@"
}
