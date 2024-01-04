#!/bin/bash
if [[ "$1" == "de" || "$1" == "dec" || "$1" == "decrypt" ]]; then
	openssl enc -d -aes-256-ctr -pbkdf2 -in $2 -out $3
fi

if [[ "$1" == "en" || "$1" == "enc" || "$1" == "encrypt" ]]; then
    openssl enc -e -aes-256-ctr -pbkdf2 -in $2 -out $2.enc
	#_encrypt
fi
