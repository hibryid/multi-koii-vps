# multi-koii-vps
It is a script that can help run Koii nodes on vps.\
If you need help or assistance, you can ask your questions in the [Koii's official Discord server](https://discord.com/invite/koii-network), especially [this channel](https://discord.com/channels/776174409945579570/1207323567503704084)
## Disclaimer
***
The project is released as is.
It was designed to easily configure koii nodes in the terminal.

Pros:
1. Much more user-friendly comparing to the official documentation
2. Multiple nodes support
3. Proxy support (for cli nodes only)
4. GUI support for VPS.
5. Possible emulation(!) of amd64 containers for arm64 architecture
(No guarantee for weak devices like Raspberry Pi)

Requirements:
1. GNU/Linux distro is required (The best for newbies is Ubuntu 20+)
2. You can run any amount of nodes, but up to 4 nodes per 1 ip only. Please keep it in mind
***

#### 1. Prepare the system
<details>
    <summary>On Ubuntu (click here)</summary>

#### Install required tools
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git jq zip unzip micro
```

#### Install docker if you don't have it
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

#### Install nodejs
```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - &&\
sudo apt-get install -y nodejs
```

#### Install koii cli (You can skip this step. It will not work on arm too)
```bash
sh -c "$(curl -sSfL https://raw.githubusercontent.com/koii-network/k2-release/master/k2-install-init_v1.16.6.sh)"
echo 'export PATH="~/.local/share/koii/install/active_release/bin:$PATH"' > ~/.bashrc
source ~/.bashrc
```

</details>

<details>
    <summary>On Arch (Soon)</summary>
</details>

#### 2. Git clone and go to the project
```bash
git clone https://github.com/hibryid/multi-koii-vps.git
cd multi-koii-vps
```

#### 3. Install some libraries
```bash
npm install @_koii/web3.js @_koii/create-task-cli @solana/web3.js
npm install -D tsx
```

#### 4. Copy the .env file
```bash
cp .env.example .env
```


<details>
    <summary style="font-size: 20px; font-weight: bold;">If you want just to run a Desktop/GUI/webtop node (Click here)</summary>

#### 5. Setup GUI
You can do it by this command or by manually editing the `.env` file
```bash
bash multi-koii.sh setup-gui
```
If you have an ARM device, prepare some images to continue:
```
bash multi-koii.sh update-images
```

#### How to run a GUI node (webtop)
Now everything is good to go.\
```bash
bash multi-koii.sh up-webtop 1
```
It will give you an address like `http://127.0.0.1:30001` where you can go and run a desktop node on your VPS. 
If you selected it to be accessed remotely, then you may have to open the given port. 
The default login is: `koii` \
You can change it the `.env` file if you wish

Reminder:
Do not run more than 4 nodes per 1 ip. Proxies are not supported here.
Edit the `.env` file and be sure that password is set.
You and only you are responsible in any cases.

</details>

<details>
    <summary style="font-size: 20px; font-weight: bold;">Area for advanced users to run CLI-VPS nodes (Click here)</summary>

#### 5. Edit the .env file
```bash
# Edit the .env file for your settings with nano or micro
nano .env
```

#### 6. Update images
```bash
bash multi-koii.sh update-images
```

#### Commands for running CLI-VPS nodes:
It is an advanced way to manage multiple nodes.\
Here is a list of examples.\
You can use any of these range number formats: `1-10` or `0001-0010`. \
(Please, keep in mind: up to 4 nodes per 1 ip only) \
I personally prefer the `0001-0010` format because each node can have its own serial number among servers.\
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
bash multi-koii.sh show-addresses 1

# Show rewards
bash multi-koii.sh show-rewards 1

# Balances, currently KOII only
bash multi-koii.sh show-balances 1

# If you want, you can set the range once, and then just use the command
bash next_docker set-range 1-3
bash next_docker show-addresses

# claim rewards
bash multi-koii.sh claim 1

# Unstake from the old task
bash multi-koii.sh unstake 1

# limit cores count to use
bash multi-koii.sh limit-cpu 1 4

# limit memory
# Example: 10G, 2500M
bash multi-koii.sh limit-ram 1 5G

# create a backup of all keys
bash multi-koii.sh backup
```

The script will give you the exact ip and port to open it in browser.
To set up a https connection you may try to use "nginx proxy manager".

#### If you need to set any custom ids, tasks and variables for nodes
And edit them in the format you like, according to the examples. \
The serial number of a raw refers to the serial number of the node
```bash
cp configs/nodes/example-proxies configs/nodes/proxies
cp configs/nodes/example-old-task-ids configs/nodes/old-task-ids
cp configs/nodes/example-node-vars configs/nodes/node-vars
cp configs/nodes/example-task-ids configs/nodes/task-ids
```
</details>

#### Additional info / Credits
This script can be identified as a helper to install some finished products of other projects.\
Anyway, according to their licences I have to list them:
1. [Binfmt](https://github.com/tonistiigi/binfmt) - cross-platform emulator collection distributed with Docker images.
2. [tun2socks](https://github.com/xjasonlyu/tun2socks) - powered by gVisor TCP/IP stack
3. [docker-webtop](https://github.com/linuxserver/docker-webtop) - Ubuntu, Alpine, Arch, and Fedora based Webtop images, Linux in a web browser supporting popular desktop environments.