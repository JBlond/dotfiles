if [[ "$OSTYPE" == "msys" ]]; then
	cd $TMP
	rm -rf *
else
	echo 'Windows only'	
fi
