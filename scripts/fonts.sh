#!/usr/bin/env bash
cd /usr/share/mintty
curl -LO https://github.com/JBlond/emojis/archive/refs/tags/1.3.0.zip
unzip 1.3.0.zip
mv emojis-1.3.0 emojis
rm 1.3.0.zip
