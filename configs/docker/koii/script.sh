#!/bin/bash

sleep 5
nohup bash -c "while true; do dockerd ; sleep 5 ; done >/dev/null 2>&1 &" 
sleep 5

if [[ -n "$PROXY" ]]; then
  GATEWAY=$(ip route | awk '/default/ {print $3}')
  INTERFACE=$(ip route | awk '/default/ {print $5}')
  #host_ip=$(curl -s ipinfo.io/ip)
  #echo $host_ip

  DNS=$DEFAULT_DNS
  sysctl net.ipv4.conf.all.rp_filter=0
  sysctl net.ipv4.conf.$INTERFACE.rp_filter=0

  ip tuntap add mode tun dev tun0
  ip addr add 198.18.0.1/15 dev tun0
  ip link set dev tun0 up
  ip route del default
  ip route add default via 198.18.0.1 dev tun0 metric 1
  ip route add default via $GATEWAY dev eth0 metric 10


  ## If udp does not work
  if [[ "$UDP" == "false" ]];then
      ip route add $DNS via $GATEWAY metric 5
  elif [[ "$UDP" == "true" ]];then
      iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to $DNS:53
      iptables -t nat -A POSTROUTING -p udp -d $DNS --dport 53 -o $INTERFACE -j MASQUERADE
  else
      echo "PROXY SUPPORT NOT SET"
      exit 1
  fi

  ## iptables or iptables-legacy
  ## udp routing
  # iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to 1.1.1.1:53
  # iptables -t nat -A POSTROUTING -p udp -d 1.1.1.1 --dport 53 -o $INTERFACE -j MASQUERADE
  echo -e "nameserver $DNS\n$(cat /etc/resolv.conf)" > /etc/resolv.conf
  nohup bash -c "while true; do tun2socks -device tun0 -proxy socks5://$PROXY -interface eth0 ; sleep 5 ; done" >/dev/null 2>&1 &
  # nohup tun2socks -device tun0 -proxy socks5://$PROXY -interface eth0 >/dev/null 2>&1 &
fi


file_path="/root/.config/koii/id.json"

if [ -e "$file_path" ]; then
    echo "Wallet exists!" >> /root/res.txt
else
    echo "Wallet does not exist!" >> /root/res.txt
    koii-keygen new --no-bip39-passphrase -o /root/.config/koii/id.json >> /root/.config/koii/seeds.txt
    chown -R $HOST_UID:$HOST_GID /root/.config/koii/
    # chmod -R $HOST_UID:$HOST_GID /root/.config/koii/wallet/
fi

cd /root/VPS-task

koii config set --url https://mainnet.koii.network
re='^[0-9]+([.][0-9]+)?$'
while true; do
    koii_balance=$(koii balance | awk '{print $1}')
    if [[ $koii_balance == "0" ]];then
        echo "Send the needed amount of $((INITIAL_STAKING_WALLET_BALANCE*2+2)) KOII: $(koii address)"
        sleep 10
    elif [ $(echo "$koii_balance > 0.0" | bc) ];then
        echo "OK: $koii_balance"
        break
    else
        echo "some error happened"
        sleep 10
    fi
done

counter=0
while ! docker info; do
    echo "Waiting docker..."
    sleep 10
    if [[ $counter -ge 3 ]];then
        echo "failed to start docker"
        exit 1
    else
        ((counter++))
    fi
done

# Import pre-installed images

file_path="/root/.lock"
if [ -e "$file_path" ]; then
    echo "NO MOD REQUIRED!" >> /root/res.txt
    # source /root/.profile
else
    sed -i "s/:latest/$KOII_IMAGE_VERSION/g" /root/VPS-task/docker-compose.yaml
    sed -i "s/INITIAL_STAKING_WALLET_BALANCE=.*/INITIAL_STAKING_WALLET_BALANCE=$INITIAL_STAKING_WALLET_BALANCE/g" /root/VPS-task/.env-local
    sed -i "s/TASKS=\".*\"/TASKS=\"$TASK_IDS\"/g" /root/VPS-task/.env-local
    sed -i "s/TASK_STAKES=.*/TASK_STAKES=$TASK_STAKES/g" /root/VPS-task/.env-local
    echo "$NODE_VARS" >> /root/VPS-task/.env-local

    sed -i 's/command: yarn initialize-start/entrypoint: ["\/bin\/sh", "-c", "apt-get update \&\& apt-get install -y --no-install-recommends libglib2.0-dev libgconf-2-4 libatk1.0-0 libatk-bridge2.0-0 libgdk-pixbuf2.0-0 libgtk-3-0 libgbm-dev libnss3-dev libxss-dev libasound2 xorg openbox libatk-adaptor libgtk-3-0 \&\& exec yarn initialize-start"]/g' /root/VPS-task/docker-compose.yaml

    for file in /images/*.tar; do
      docker load <$file
    done
    touch $file_path
fi

docker compose up
echo "what?"
sleep 30