
# shadowsocks
FROM alpine:3.19 AS shadowsocks
ENV SS_LIBEV_VERSION v3.3.5
RUN apk upgrade \
    && apk add bash tzdata rng-tools runit \
    && apk add --virtual .build-deps \
        autoconf \
        automake \
        build-base \
        curl \
        c-ares-dev \
        libev-dev \
        libtool \
        libsodium-dev \
        mbedtls-dev \
        pcre-dev \
        tar \
        git \
		libcap \
		linux-headers 

RUN git clone https://github.com/shadowsocks/shadowsocks-libev.git
RUN cd shadowsocks-libev \
    && git checkout tags/${SS_LIBEV_VERSION} -b ${SS_LIBEV_VERSION} \
    && git submodule update --init --recursive \
    && ./autogen.sh \
    && ./configure --prefix=/usr --disable-documentation \
    && make install

# kcptun
FROM alpine:latest AS kcptun
ENV KCP_VERSION 20241227
RUN apk upgrade \
    && apk add bash curl 

ENV KCP_DOWNLOAD_URL https://github.com/xtaci/kcptun/releases/download/v${KCP_VERSION}/kcptun-linux-amd64-${KCP_VERSION}.tar.gz
RUN mkdir -p /opt/kcptun
RUN curl -sSLO ${KCP_DOWNLOAD_URL} \
    && tar -zxf kcptun-linux-amd64-${KCP_VERSION}.tar.gz \
    && mv server_linux_amd64 /opt/kcptun/kcpserver \
    && mv client_linux_amd64 /opt/kcptun/kcpclient 
	

# v2ray-plugin
FROM golang:1.22-alpine as v2ray
RUN apk upgrade \
    && apk add bash curl git
RUN git clone https://github.com/shadowsocks/v2ray-plugin.git
RUN cd v2ray-plugin && go build -o /opt/v2ray-plugin
	


# 运行环境
FROM alpine:latest 
RUN apk upgrade \
    && apk add bash dos2unix runit \
    && rm -rf /var/cache/apk/*

# 插件
COPY --from=kcptun /opt/kcptun /usr/bin
COPY --from=v2ray /opt/v2ray-plugin /usr/bin

# 拷贝ss
COPY --from=shadowsocks /usr/bin/ss-* /usr/bin
COPY --from=shadowsocks /usr/lib/libmbedcrypto.so.7 /usr/lib/libmbedcrypto.so.7
COPY --from=shadowsocks /usr/lib/libev.so.4 /usr/lib/libev.so.4
COPY --from=shadowsocks /usr/lib/libcares.so.2 /usr/lib/libcares.so.2
COPY --from=shadowsocks /usr/lib/libpcre.so.1 /usr/lib/libpcre.so.1
COPY --from=shadowsocks /usr/lib/libsodium.so.26 /usr/lib/libsodium.so.26


COPY runit /etc/service
COPY entrypoint.sh /entrypoint.sh

RUN chmod -R 777 /etc/service \
	&& chmod -R 777 /entrypoint.sh \
    && dos2unix /etc/service/kcptun/run \
	&& dos2unix /etc/service/shadowsocks/run \
	&& dos2unix /entrypoint.sh 



ENTRYPOINT ["/entrypoint.sh"]
