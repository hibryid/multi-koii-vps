#!/bin/bash

if ! which "koii-node" >/dev/null;then
  apt update && apt install wget desktop-file-utils -y
  latest_version=$(curl --silent -qI https://github.com/koii-network/koii-node/releases/latest | awk -F [/v] '/^location/ {print  substr($NF, 1, length($NF)-1)}')
  wget "https://github.com/koii-network/koii-node/releases/download/v$latest_version/koii-node-$latest_version-linux-amd64.deb" -O linux-amd64.deb
  dpkg -i linux-amd64.deb
  ln -s /usr/share/applications/koii-node.desktop /config/Desktop/koii-node.desktop 2>/dev/null
  ln -s /usr/share/applications/koii-node.desktop /etc/xdg/autostart/koii-node.desktop 2>/dev/null
  rm /etc/xdg/autostart/org.kde.plasma-welcome.desktop 2>/dev/null
fi
