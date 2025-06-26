
# 1. Базовый образ
FROM kalilinux/kali-rolling

# 2. Системные зависимости
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git make wget tar curl ca-certificates \
    postgresql postgresql-contrib redis-server \
    nodejs npm && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Go 1.23.5
ENV GO_VERSION=1.23.5
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz


# 4. Переменные среды Go
ENV GOPATH=/root/go
ENV GOTOOLCHAIN=local
ENV PATH=/usr/local/go/bin:${GOPATH}/bin:${PATH}


# 5. Сборка Storj-sim (+ вся backend часть)

RUN git clone https://github.com/storj/storj.git /storj && \
    cd /storj && \
    make install-sim && \
    storj-sim --help >/dev/null


# 5b. Сборка Web-консоли Satellite 
RUN cd /storj/web/satellite && \
    npm ci --legacy-peer-deps && \
    npm run build            #  сгенерирует /storj/web/satellite/dist


# 6. Ganache CLI (локальный Ethereum)
RUN npm install -g ganache-cli


# 7. Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
