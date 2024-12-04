FROM ubuntu:jammy
ENV DEBIAN_FRONTEND=noninteractive

ARG UID
ARG GID

RUN apt update && \
    apt install -y sudo && \
    if [ "$UID" != 0 ]; then \
    addgroup --gid $GID koii && \
    adduser --uid $UID --gid $GID --disabled-password --gecos "" koii && \
    echo 'koii ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers ;fi


RUN apt update && apt install tmux wget git nano jq iputils-ping htop bc unzip curl iproute2 iptables sudo -y
RUN wget https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/tun2socks-linux-amd64-v3.zip -O tun2socks.zip && \
    unzip tun2socks.zip && rm tun2socks.zip &&\
    mv tun2s* tun2socks &&\
    mv tun2socks /usr/local/bin/ && \
    chmod +x /usr/local/bin/tun2socks

RUN sudo apt-get install ca-certificates curl
RUN sudo install -m 0755 -d /etc/apt/keyrings
RUN sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
RUN sudo chmod a+r /etc/apt/keyrings/docker.asc

RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN sudo apt-get update

RUN sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# RUN sudo groupadd docker
RUN sudo usermod -aG docker root

RUN sh -c "$(curl -sSfL https://raw.githubusercontent.com/koii-network/k2-release/master/k2-install-init_v1.16.4.sh)"
RUN echo 'export PATH="/root/.local/share/koii/install/active_release/bin:$PATH"' >> /root/.bashrc
RUN . /root/.bashrc

RUN cd /root && git clone https://github.com/koii-network/VPS-task && cd VPS-task
RUN sed -i 's/ENVIRONMENT=".*"/ENVIRONMENT="production"/g' /root/VPS-task/.env-local
RUN sed -i 's/K2_NODE_URL=".*"/K2_NODE_URL="https:\/\/testnet.koii.network"/g' /root/VPS-task/.env-local

# COPY ./images /images
COPY script.sh /root/start.sh
RUN chmod +x /root/start.sh
ENTRYPOINT ["/bin/bash", "-l"]
CMD ["/root/start.sh"]
