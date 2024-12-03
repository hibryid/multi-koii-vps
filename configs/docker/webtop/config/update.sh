#!/bin/bash

# latest_version="0.9.14"
latest_version=$(curl --silent -qI https://github.com/koii-network/koii-node/releases/latest | awk -F [/v] '/^location/ {print  substr($NF, 1, length($NF)-1)}')
wget "https://github.com/koii-network/koii-node/releases/download/v$latest_version/koii-node-$latest_version-linux-amd64.deb" -O linux-amd64.deb
pkill koii-node
sudo dpkg -i linux-amd64.deb
rm linux-amd64.deb

echo "==============="
echo "done..you may close the terminal and start your node again"
echo "==============="

sleep 20
exit