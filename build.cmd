docker build ./ --build-arg HTTP_PROXY=http://127.0.0.1:1080 -t lianshufeng/shadowsocks

docker run --rm -it --entrypoint /bin/bash lianshufeng/shadowsocks 