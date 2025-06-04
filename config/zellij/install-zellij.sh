#!/usr/bin/env bash
sudo rm -rf /usr/local/bin/zellij
curl -LO https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz
sudo tar -C /usr/local/bin -xzf zellij-x86_64-unknown-linux-musl.tar.gz
rm zellij-x86_64-unknown-linux-musl.tar.gz
