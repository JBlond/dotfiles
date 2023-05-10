#!/bin/bash
cd /usr/share/mintty
curl -LO https://github.com/JBlond/emojis/archive/refs/tags/1.1.0.zip
unzip 1.1.0.zip
mv emojis-1.1.0 emojis
rm 1.1.0.zip
