#!/bin/sh

#ubuntu 
#apt-get install -y libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make build-essential

# CentOS
yum install -y libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make build-essential

# Script to compile nginx on ubuntu with lua support.

NGX_VERSION='1.8.0'
LUAJIT_VERSION='2.0.4'
LUAJIT_MAJOR_VERSION='2.0'
NGX_DEVEL_KIT_VERSION='0.2.19'
LUA_NGINX_MODULE_VERSION='0.9.16'

NGINX_INSTALL_PATH='/etc/nginx'
ERROR_LOG_PATH='/var/log/nginx/error.log'
ACCESS_LOG_PATH='/var/log/nginx/access.log'
NGINX_USER='www-data'
NGINX_GROUP='www-data'

# Download
if [ ! -f ./nginx-${NGX_VERSION}.tar.gz ]; then
    wget http://nginx.org/download/nginx-${NGX_VERSION}.tar.gz
fi

if [ ! -f ./LuaJIT-${LUAJIT_VERSION}.tar.gz ]; then
    wget http://luajit.org/download/LuaJIT-${LUAJIT_VERSION}.tar.gz
fi

if [ ! -f ./ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.tar.gz ]; then
    wget https://github.com/simpl/ngx_devel_kit/archive/v${NGX_DEVEL_KIT_VERSION}.tar.gz \
        -O ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.tar.gz
fi

if [ ! -f ./lua-nginx-module-${LUA_NGINX_MODULE_VERSION}.tar.gz ]; then
    wget https://github.com/openresty/lua-nginx-module/archive/v${LUA_NGINX_MODULE_VERSION}.tar.gz \
        -O lua-nginx-module-${LUA_NGINX_MODULE_VERSION}.tar.gz
fi

# Extract
if [ ! -d ./nginx-${NGX_VERSION} ]; then
    tar xvf nginx-${NGX_VERSION}.tar.gz
fi

if [ ! -d ./LuaJIT-${LUAJIT_VERSION} ]; then
    tar xvf LuaJIT-${LUAJIT_VERSION}.tar.gz
fi

if [ ! -d ./ngx_devel_kit-${NGX_DEVEL_KIT_VERSION} ]; then
    tar xvf ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.tar.gz
fi

if [ ! -d ./lua-nginx-module-${LUA_NGINX_MODULE_VERSION} ]; then
    tar xvf lua-nginx-module-${LUA_NGINX_MODULE_VERSION}.tar.gz
fi

# Install luajit
cd ./LuaJIT-${LUAJIT_VERSION} && sudo make install && cd ..

NGX_DEVEL_KIT_PATH=$(pwd)/ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}
LUA_NGINX_MODULE_PATH=$(pwd)/lua-nginx-module-${LUA_NGINX_MODULE_VERSION}

# Compile And Install Nginx
cd ./nginx-${NGX_VERSION} && \
    LUAJIT_LIB=/usr/local/lib/lua LUAJIT_INC=/usr/local/include/luajit-${LUAJIT_MAJOR_VERSION} \
    ./configure --prefix=${NGINX_INSTALL_PATH} --conf-path=${NGINX_INSTALL_PATH}/nginx.conf --pid-path=/run/nginx.pid \
    --sbin-path=/usr/sbin/nginx --lock-path=/run/nginx.lock --error-log-path=${ERROR_LOG_PATH} \
    --http-log-path=${ACCESS_LOG_PATH} --user=www-data --group=www-data \
    --with-ld-opt='-Wl,-rpath,/usr/local/lib/lua' \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_gzip_static_module \
    --with-http_stub_status_module \
    --with-ipv6 \
    --with-pcre-jit \
    --add-module=${NGX_DEVEL_KIT_PATH} \
    --add-module=${LUA_NGINX_MODULE_PATH} \
    && make -j8 && sudo make install


apt-get install -y liblua5.1-0-dev lua5.1

# isntall luarocks
if [ ! -f ./luarocks-2.2.2.tar.gz ]; then
    wget http://keplerproject.github.io/luarocks/releases/luarocks-2.2.2.tar.gz
fi

if [ ! -d ./luarocks-2.2.2 ]; then
    tar xvf luarocks-2.2.2.tar.gz
fi

# Install luajit
cd ./luarocks-2.2.2 && ./configure && sudo make build && make install && cd ..

# install lua-cjson
if [ ! -f ./lua-cjson-2.1.0.3.tar.gz ]; then
    # wget http://www.kyne.com.au/~mark/software/download/lua-cjson-2.1.0.tar.gz
    wget https://codeload.github.com/openresty/lua-cjson/tar.gz/2.1.0.3 -O lua-cjson-2.1.0.3.tar.gz
fi

if [ ! -d ./lua-cjson-2.1.0.3 ]; then
    tar xvf lua-cjson-2.1.0.3.tar.gz
fi
cd ./lua-cjson-2.1.0.3 && luarocks make && cd ..

# install lua-redis
mkdir /usr/local/share/luajit-${LUAJIT_VERSION}/resty/
wget https://raw.githubusercontent.com/openresty/lua-resty-redis/master/lib/resty/redis.lua -O /usr/local/share/luajit-2.0.4/resty/redis.lua


# mkdir ${NGINX_INSTALL_PATH}/lua
# wget https://gist.githubusercontent.com/weelion/d9e5a8b4401c1bfeafdb/raw/aad5f5644facf3a1f8a2e28cb972aa220aea61d3/api.lua \
#    -O ${NGINX_INSTALL_PATH}/lua/api_base.lua

service nginx restart

# 如果动态libluajit-5.1.so.2无法加载需要添加软连接到/lib
# ln -s /usr/local/lib/libluajit-5.1.so.2 /lib/libluajit-5.1.so.2
