FROM alpine:3.20

LABEL maintainer="lianshufeng <251708339@qq.com>"

ARG TZ='Asia/Shanghai'

ENV TZ ${TZ}
ENV SS_LIBEV_VERSION v3.3.5
ENV KCP_VERSION 20240713
ENV V2RAY_VERSION v1.3.2
ENV SS_DOWNLOAD_URL https://github.com/shadowsocks/shadowsocks-libev.git 
ENV KCP_DOWNLOAD_URL https://github.com/xtaci/kcptun/releases/download/v${KCP_VERSION}/kcptun-linux-amd64-${KCP_VERSION}.tar.gz
ENV PLUGIN_OBFS_DOWNLOAD_URL https://github.com/shadowsocks/simple-obfs.git
ENV PLUGIN_V2RAY_DOWNLOAD_URL https://github.com/shadowsocks/v2ray-plugin/releases/download/${V2RAY_VERSION}/v2ray-plugin-linux-amd64-${V2RAY_VERSION}.tar.gz
ENV LINUX_HEADERS_DOWNLOAD_URL=https://dl-cdn.alpinelinux.org/alpine/v3.20/main/x86_64/linux-headers-6.6-r0.apk

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
    && curl -sSL ${LINUX_HEADERS_DOWNLOAD_URL} > /linux-headers.apk \
    && apk add --virtual .build-deps-kernel /linux-headers.apk \
    && git clone ${SS_DOWNLOAD_URL} \
    && (cd shadowsocks-libev \
    && git checkout tags/${SS_LIBEV_VERSION} -b ${SS_LIBEV_VERSION} \
    && git submodule update --init --recursive \
    && ./autogen.sh \
    && ./configure --prefix=/usr --disable-documentation \
    && make install) \
    && git clone ${PLUGIN_OBFS_DOWNLOAD_URL} \
    && (cd simple-obfs \
    && git submodule update --init --recursive \
    && ./autogen.sh \
    && ./configure --disable-documentation \
    && make install) \
    && curl -o v2ray_plugin.tar.gz -sSL ${PLUGIN_V2RAY_DOWNLOAD_URL} \
    && tar -zxf v2ray_plugin.tar.gz \
    && mv v2ray-plugin_linux_amd64 /usr/bin/v2ray-plugin \
    && curl -sSLO ${KCP_DOWNLOAD_URL} \
    && tar -zxf kcptun-linux-amd64-${KCP_VERSION}.tar.gz \
    && mv server_linux_amd64 /usr/bin/kcpserver \
    && mv client_linux_amd64 /usr/bin/kcpclient \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && adduser -h /tmp -s /sbin/nologin -S -D -H shadowsocks \
    && adduser -h /tmp -s /sbin/nologin -S -D -H kcptun \
    && apk del .build-deps .build-deps-kernel \
	&& apk add --no-cache \
      $(scanelf --needed --nobanner /usr/bin/ss-* /usr/local/bin/obfs-* \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | sort -u) \
    && rm -rf /linux-headers.apk \
        kcptun-linux-amd64-${KCP_VERSION}.tar.gz \
        shadowsocks-libev \
        simple-obfs \
        v2ray_plugin.tar.gz \
        /etc/service \
        /var/cache/apk/*


COPY runit /etc/service
COPY entrypoint.sh /entrypoint.sh


RUN apk add dos2unix \
    && chmod -R 777 /etc/service \
	&& chmod -R 777 /entrypoint.sh \
    && dos2unix /etc/service/kcptun/run \
	&& dos2unix /etc/service/shadowsocks/run \
	&& dos2unix /entrypoint.sh 



SHELL ["/bin/bash"]



ENTRYPOINT ["/entrypoint.sh"]
