function us --wraps=ls\ -la\ \|\ grep\ ^-\ \|\ awk\ \'\{print\ \$9\}\'\ \|\ grep\ ^\\\\. --description alias\ us=ls\ -la\ \|\ grep\ ^-\ \|\ awk\ \'\{print\ \$9\}\'\ \|\ grep\ ^\\\\.
	ls -la | grep ^- | awk '{print $9}' | grep ^\\. $argv
end
