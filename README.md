# 

## Disclaimer
***
The project is released as is.
***


### Install required tools

```
sudo apt-get update
sudo apt-get install -y ca-certificates curl expect git
```

### Install docker
```
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin jq unzip -y

sudo groupadd docker
sudo usermod -aG docker $USER
reset
```

### Check if it is running:
```
sudo systemctl status sysbox -n20
```

### Install nodejs
```
curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash - &&\
sudo apt-get install -y nodejs
```

### Install koii cli
```
sh -c "$(curl -sSfL https://raw.githubusercontent.com/koii-network/k2-release/master/k2-install-init_v1.16.4.sh)"
echo 'export PATH="~/.local/share/koii/install/active_release/bin:$PATH"' > ~/.profile
source ~/.profile
```

### Git clone and go to the project
```
git clone https://github.com:hibryid/multi-koii-vps.git
cd multi-koii
```

### Updating images
```bash
# Copy and edit for your settings
cp .env.example .env


source .env

bash multi-koii.sh update-images
```

В папку закинуть proxies.txt файл с прокси такого формата:
```
123.123.123.123:1085

или
login:pass@123.123.123.123:1080
```

Команды для запуска:
```
# проверка при помощи checker
bash next_docker.sh up-checker 0001

# Если надо запустить 1 контейнер с определенным номером
bash next_docker.sh up-dind 0001

# запустить несколько контейнер в каком-то диапазоне
bash next_docker.sh up-dind 0001-0010

# Удалить контейнер
bash next_docker.sh down 0001

# Удалить несколько
bash next_docker.sh down 0001-0010

# Проверить стейк
bash next_docker.sh check-stake 0001-0010

# Получить адреса кошельков
bash next_docker.sh get-addresses 0001-0010

# Проверить награды у тасков
bash next_docker.sh get-rewards 0001-0010

# Балансы
bash next_docker.sh get-balances 0001-0010

# Получить другие ошибки
bash next_docker.sh other-errors 0001-0010

# Можно застолбить диапазон, чтобы каждый не указывать его
bash next_docker set-range 0001-0010
bash next_docker get-rewards

# Вывести награды
sudo bash next_docker.sh withdraw 0001-0010

# Анстейкнуть из заданий
sudo bash next_docker.sh unstake 0001-0010
```

### Получение всех адресов для пополнения из koii desktop
Сверять можно по логам из ctop
```
##tail меняется номер кошелька от которого выводить
grep pubkey koii-keys/koii-*/wallet/seeds.txt | awk '{print $2}' | tail -n +1
```

Ограничить вывод до первых 10 адресов можно так:
```
cat koii-keys/koii-*/wallet/seeds.txt | grep pubkey | awk '{print $2}' | tail -n +1 | head -n +10
```


### Вывод с кошельков
1. Отредактировать адрес в .env файле
2. Запустить апдейт npx модуля заранее
```
sudo npx @_koii/create-task-cli@0.1.41
```
3. Запустить скрипт
```
sudo bash next_docker.sh withdraw 0001-0010
```


# Проверка кошельков для рестейка

Проверка
```
sudo bash next_docker.sh check-stake 0001
```

Команда для перевода по кошелькам
```
cat wallets_to_fund.txt | xargs -n 1 -I % koii transfer % 20
```

Запуска рестейка
```
sudo bash next_docker.sh restake 0001
```

________________ команды в кэше, не трогать _______________
```
echo $(seq -w 20001 21000) | xargs -n 1 echo ip: | sed 's/ //g' | tee -a proxies.txt
```

```
while true; do yes "y" | sudo bash next_docker.sh other-errors 0001-0250 ; echo "sleeping.." && sleep 1800 ; done
```

```
while true; do bash next_docker.sh withdraw 0001-0250 ; echo "sleeping.." && sleep 14400 ; done
```


```
apt-get update \
    && apt-get install -y wget gnupg \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

apt-get update && export DEBIAN_FRONTEND=noninteractive && apt-get -y install --no-install-recommends xorg openbox libnss3 libasound2 libatk-adaptor libgtk-3-0
```