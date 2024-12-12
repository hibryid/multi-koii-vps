FROM ubuntu:24.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y curl ninja-build git build-essential pkg-config libudev-dev cmake llvm libclang-dev protobuf-compiler

RUN sh -c "$(curl -sSfL https://raw.githubusercontent.com/koii-network/k2-release/master/k2-install-init_v1.16.5.sh)"

FROM ubuntu:24.04

RUN apt update && \
    apt install -y curl && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /root/.local/share/koii/install/active_release/bin/koii /usr/local/bin/koii
RUN chmod +x /usr/local/bin/koii && /usr/local/bin/koii config set --url https://testnet.koii.network