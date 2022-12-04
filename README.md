## shadowsocks

### 打开姿势
```` sh
docker run -dt --restart=always --name ss -p 8756:6443 -p 8687:6500/udp lianshufeng/shadowsocks -s "-s 0.0.0.0 -p 6443 -m xchacha20-ietf-poly1305 -k xiaofengfeng" -x -e "kcpserver" -k "-t 127.0.0.1:6443 -l :6500 -mode fast3"
````

### 命令行
```` sh
ss-server -s 0.0.0.0 -p 6443 -m xchacha20-ietf-poly1305 -k xiaofengfeng -p 80 --plugin v2ray-plugin --plugin-opts server
````


### v2ray simple
````shell
version: "3"

services:
  shadowsocks:
    image: lianshufeng/shadowsocks
    ports:
      - "8756:6443"
      - "80:80"
      - "8687:6500/udp"
    container_name: ss
    restart: always
    command: -s "-s 0.0.0.0 -p 6443 -m xchacha20-ietf-poly1305 -k xiaofengfeng -p 80 --plugin v2ray-plugin --plugin-opts server " -x -e "kcpserver" -k "-t 127.0.0.1:6443 -l :6500 -mode fast3"
````

### v2ray ssl kcptun
- .env
````shell
#证书路径
certPath=/opt/docker/nginx/cert/letsencrypt/archive/dzurl.top
certFile=fullchain1.pem
certKeyFile=privkey1.pem

#密码
password=xiaofengfeng

#加密方式
mode=xchacha20-ietf-poly1305

#域名
v2ray_host=ss.dzurl.top
````
- docker-compose.yml
````shell
version: "3"

services:
  ss_v2ray_web:
    image: lianshufeng/shadowsocks
    ports:
      - "8080:80"
    container_name: ss_v2ray_web
    restart: always
    command: -s "-s 0.0.0.0 -p 6443 -m ${mode} -k ${password} -p 80 --plugin v2ray-plugin --plugin-opts server"

  ss_v2ray_ssl:
    image: lianshufeng/shadowsocks
    ports:
      - "8443:443"
    container_name: ss_v2ray_ssl
    volumes:
      - "${certPath}:/cert"
    restart: always
    command: -s "-s 0.0.0.0 -p 6443 -m ${mode} -k ${password} -p 443 --plugin v2ray-plugin --plugin-opts server;tls;host=${v2ray_host};cert=/cert/${certFile};key=/cert/${certKeyFile}"

  ss_kcptun:
    image: lianshufeng/shadowsocks
    ports:
      - "8756:6443"
      - "8687:6500/udp"
    container_name: ss_kcptun
    restart: always
    command: -s "-s 0.0.0.0 -p 6443 -m ${mode} -k ${password}" -x -e "kcpserver" -k "-t 127.0.0.1:6443 -l :6500 -mode fast3"
````




### 防火墙
````shell
sudo firewall-cmd --add-port=8443/tcp --permanent
sudo firewall-cmd --add-port=8756/tcp --permanent
sudo firewall-cmd --add-port=8687/udp --permanent
firewall-cmd --reload 
````

### 支持选项

- `-m` : 指定 shadowsocks 命令，默认为 `ss-server`
- `-s` : shadowsocks-libev 参数字符串
- `-x` : 开启 kcptun 支持
- `-e` : 指定 kcptun 命令，默认为 `kcpserver` 
- `-k` : kcptun 参数字符串

### 选项描述

- `-m` : 参数后指定一个 shadowsocks 命令，如 ss-local，不写默认为 ss-server；该参数用于 shadowsocks 在客户端和服务端工作模式间切换，可选项如下: `ss-local`、`ss-manager`、`ss-nat`、`ss-redir`、`ss-server`、`ss-tunnel`
- `-s` : 参数后指定一个 shadowsocks-libev 的参数字符串，所有参数将被拼接到 `ss-server` 后
- `-x` : 指定该参数后才会开启 kcptun 支持，否则将默认禁用 kcptun
- `-e` : 参数后指定一个 kcptun 命令，如 kcpclient，不写默认为 kcpserver；该参数用于 kcptun 在客户端和服务端工作模式间切换，可选项如下: `kcpserver`、`kcpclient`
- `-k` : 参数后指定一个 kcptun 的参数字符串，所有参数将被拼接到 `kcptun` 后

### 命令示例

**Server 端**

``` sh
docker run -dt --name ssserver -p 6443:6443 -p 6500:6500/udp lianshufeng/shadowsocks -m "ss-server" -s "-s 0.0.0.0 -p 6443 -m chacha20-ietf-poly1305 -k test123" -x -e "kcpserver" -k "-t 127.0.0.1:6443 -l :6500 -mode fast3"
```

**以上命令相当于执行了**

``` sh
ss-server -s 0.0.0.0 -p 6443 -m xchacha20-ietf-poly1305 -k xiaofengfeng
kcpserver -t 127.0.0.1:6443 -l :6500 -mode fast3
```

**Client 端**

``` sh
docker run -dt --name ssclient -p 1080:1080 lianshufeng/shadowsocks -m "ss-local" -s "-s 127.0.0.1 -p 6500 -b 0.0.0.0 -l 1080 -m chacha20-ietf-poly1305 -k test123" -x -e "kcpclient" -k "-r SSSERVER_IP:6500 -l :6500 -mode fast2"
```

**以上命令相当于执行了** 

``` sh
ss-local -s 127.0.0.1 -p 6500 -b 0.0.0.0 -l 1080 -m chacha20-ietf-poly1305 -k test123
kcpclient -r SSSERVER_IP:6500 -l :6500 -mode fast2
```

**关于 shadowsocks-libev 和 kcptun 都支持哪些参数请自行查阅官方文档，本镜像只做一个拼接**

**注意：kcptun 映射端口为 udp 模式(`6500:6500/udp`)，不写默认 tcp；shadowsocks 请监听 0.0.0.0**


### 环境变量支持


|环境变量|作用|取值|
|-------|---|---|
|SS_MODULE|shadowsocks 启动命令| `ss-local`、`ss-manager`、`ss-nat`、`ss-redir`、`ss-server`、`ss-tunnel`|
|SS_CONFIG|shadowsocks-libev 参数字符串|所有字符串内内容应当为 shadowsocks-libev 支持的选项参数|
|KCP_FLAG|是否开启 kcptun 支持|可选参数为 true 和 false，默认为 fasle 禁用 kcptun|
|KCP_MODULE|kcptun 启动命令| `kcpserver`、`kcpclient`|
|KCP_CONFIG|kcptun 参数字符串|所有字符串内内容应当为 kcptun 支持的选项参数|


使用时可指定环境变量，如下

``` sh
docker run -dt --name ss -p 6443:6443 -p 6500:6500/udp -e SS_CONFIG="-s 0.0.0.0 -p 6443 -m chacha20-ietf-poly1305 -k test123" -e KCP_MODULE="kcpserver" -e KCP_CONFIG="-t 127.0.0.1:6443 -l :6500 -mode fast2" -e KCP_FLAG="true" lianshufeng/shadowsocks
```


### 测试
````shell
curl --socks5-hostname 127.0.0.1:1080 www.google.com
````

#### shadowsocks
[shadowsocks](https://github.com/shadowsocks/shadowsocks-windows/releases/)

#### kcptun
[kcptun](https://github.com/xtaci/kcptun/releases)
````shell
client_windows_amd64.exe -r 204.44.94.8:8687 -l :1030 -mode fast3
````

####  v2ray-plugin
[v2ray](https://github.com/shadowsocks/v2ray-plugin/releases)
````shell
#程序
v2ray-plugin_windows_amd64
#选项
tls;host=ss.dzurl.top
````


#### 浏览器插件
[进入下载页面](https://github.com/FelisCatus/SwitchyOmega/releases)


