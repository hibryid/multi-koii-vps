# multi-koii-vps

It is a script that can help run Koii nodes on vps.

## Disclaimer
***
The project is released as is.
It was designed to easily configure in the terminal

Requirements:
1. Ubuntu 20+ is required
2. You can run up to 4 nodes per 1 ip only. Please keep it in mind
***


### Install required tools
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git jq zip unzip
```

### Install docker if you don't have it
```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
reset
```

### Git clone and go to the project
```bash
git clone https://github.com/hibryid/multi-koii-vps.git
cd multi-koii-vps
```

### Install nodejs and some libraries
```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - &&\
sudo apt-get install -y nodejs
npm install @_koii/web3.js @_koii/create-task-cli
npm install -D tsx
```

### Install koii cli
```bash
sh -c "$(curl -sSfL https://raw.githubusercontent.com/koii-network/k2-release/master/k2-install-init_v1.16.4.sh)"
echo 'export PATH="~/.local/share/koii/install/active_release/bin:$PATH"' > ~/.bashrc
source ~/.bashrc
```


### Updating images
```bash
# Copy and edit for your settings
cp .env.example .env
bash multi-koii.sh update-images
```

### Commands for running nodes:
Here is a list of examples.\
You can use any of these range number formats: `1-10` or `0001-0010`. \
(Please, keep in mind: up to 4 nodes per 1 ip only) \
The most general typical format: `<command> <a number or a range on nodes>`
```bash
# Running a single node
bash multi-koii.sh up 1
# bash multi-koii.sh up 0001

# Running 3 nodes
bash multi-koii.sh up 1-3
# bash multi-koii.sh up 0001-0003

# show logs
# You will have to send some KOII if it asks
# Send koii and kpl tokens only to the system key address
bash multi-koii.sh logs 1

# Completely stop the node and delete its container (wallets are safe)
bash multi-koii.sh down 1

# Stop some containers
bash multi-koii.sh down 1-3

# show stakes
# The best metric to see if tokens are staked on the certain task
bash multi-koii.sh show-stakes 1

# show submissions on the tasks
# The best summary indicator for tracking the nodes
bash multi-koii.sh show-submissions 1

# Show wallet addresses
# Send koii and kpl tokens only to the system key address
bash multi-koii.sh show-addresses 0001

# Show rewards
bash multi-koii.sh show-rewards 1

# Balances, currently KOII only
bash multi-koii.sh show-balances 1

# If you want, you can set the range once, and then just use the command
bash next_docker set-range 1-3
bash next_docker show-addresses

# claim rewards
# Will be added soon
bash multi-koii.sh claim 1

# Unstake from the old task
# Will be added soon
sudo bash multi-koii.sh unstake 1
```

### If you want to run a GUI node (webtop)
Do not run more than 4 nodes per 1 ip. Proxies are not supported here.
Edit the `.env` file and be sure that password is set.
You and only you are responsible is any cases.

```bash
bash multi-koii.sh up-webtop 1
```
The script will give you the exact ip and port to open it in browser.
To setup a https connection you may try to use "nginx proxy manager".

### If you need to set any custom ids, tasks and variables for nodes
And edit them in the format you like, according to the examples. \
The number of a raw is the number of the node
```bash
cp configs/nodes/example-proxies configs/nodes/proxies
cp configs/nodes/example-old-task-ids configs/nodes/old-task-ids
cp configs/nodes/example-node-vars configs/nodes/node-vars
cp configs/nodes/example-task-ids configs/nodes/task-ids
```
