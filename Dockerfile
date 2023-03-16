#############################
#     设置公共的变量         #
#############################
FROM alpine:latest AS base
# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=C.UTF-8
ENV LANG=$LANG

# 镜像变量
ARG DOCKER_IMAGE=danxiaonuo/php
ENV DOCKER_IMAGE=$DOCKER_IMAGE
ARG DOCKER_IMAGE_OS=alpine
ENV DOCKER_IMAGE_OS=$DOCKER_IMAGE_OS
ARG DOCKER_IMAGE_TAG=latest
ENV DOCKER_IMAGE_TAG=$DOCKER_IMAGE_TAG

# ##############################################################################

# ***** 设置变量 *****

# 工作目录
ARG PHP_DIR=/data/php
ENV PHP_DIR=$PHP_DIR
# 环境变量
ARG PATH=/data/php/bin:$PATH
ENV PATH=$PATH
# 源文件下载路径
ARG DOWNLOAD_SRC=/tmp/src
ENV DOWNLOAD_SRC=$DOWNLOAD_SRC

# PHP版本
# https://github.com/php
ARG PHP_VERSION=8.2.3
ENV PHP_VERSION=$PHP_VERSION
# PHP编译参数
ARG PHP_BUILD_CONFIG="\
    --prefix=${PHP_DIR} \
    --with-config-file-path=${PHP_DIR}/etc \
    --with-fpm-user=nginx  \
    --with-fpm-group=nginx \
    --with-curl \
    --with-freetype \
    --enable-gd \
    --with-gettext \
    --with-iconv-dir \
    --with-kerberos \
    --with-libxml \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-openssl \
    --with-external-pcre \
    --with-pdo-sqlite \
    --with-pear \
    --with-xmlrpc \
    --with-xsl \
    --with-zlib \
    --with-jpeg \
    --with-mhash \
    --with-sqlite3 \
    --with-bz2 \
    --with-cdb \
    --with-gmp \
    --with-readline \
    --with-ldap \
    --with-tidy \
    --with-imap \
    --with-imap-ssl \
    --with-imap-ssl \
    --with-zlib-dir \
    --without-pdo-sqlite \
    --with-libxml \
    --with-zip \
    --enable-fpm \
    --enable-cgi \
    --enable-bcmath \
    --enable-mysqlnd-compression-support \
    --enable-inline-optimization \
    --enable-mbregex \
    --enable-mbstring \
    --enable-opcache \
    --enable-pcntl \
    --enable-shmop \
    --enable-soap \
    --enable-sockets \
    --enable-sysvsem \
    --enable-xml \
    --enable-session \
    --enable-ftp \
    --enable-shared  \
    --enable-calendar \
    --enable-dom \
    --enable-exif \
    --enable-fileinfo \
    --enable-filter \
    --enable-json \
    --enable-pdo \
    --enable-simplexml \
    --enable-sysvmsg \
    --enable-sysvshm \
    --enable-cli \
    --enable-ctype \
    --enable-posix \
    --enable-opcache \
    --enable-tokenizer \
    --enable-dba \
    --enable-xmlreader \
    --enable-xmlwriter \
    --enable-intl \
    --enable-libgcc \
"
ENV PHP_BUILD_CONFIG=$PHP_BUILD_CONFIG

# 扩展插件版本
# redis
# https://pecl.php.net/package/redis
ARG REDIS_VERSION=5.3.7
ENV REDIS_VERSION=$REDIS_VERSION
# swoole
# https://pecl.php.net/package/swoole
ARG SWOOLE_VERSION=5.0.2
ENV SWOOLE_VERSION=$SWOOLE_VERSION
# mongodb
# https://pecl.php.net/package/mongodb
ARG MONGODB_VERSION=1.15.1
ENV MONGODB_VERSION=$MONGODB_VERSION

# 构建安装依赖
ARG BUILD_DEPS="\
    curl \
    g++ \
    gcc \
    libc-dev \
    geoip-dev \
    gzip \
    make \
    openssl-dev \
    pcre2-dev \
    tar \
    autoconf \
    dpkg-dev \
    dpkg \
    file \
    pkgconf \
    re2c \
    zlib-dev"
ENV BUILD_DEPS=$BUILD_DEPS

ARG PHP_BUILD_DEPS="\
    ca-certificates \
    openssl \
    tar \
    xz \
    bison \
    readline \
    readline-dev \
    libxslt \
    libxslt-dev \
    libxml2 \
    libxml2-dev \
    openssl \
    openssl-dev \
    bzip2 \
    bzip2-dev \
    curl \
    curl-dev \
    freetype \
    freetype-dev \
    libpng \
    libpng-dev \
    libwebp \
    libwebp-dev \
    libjpeg-turbo \
    libjpeg-turbo-dev \
    libsodium \
    libsodium-dev \
    argon2-dev \
    coreutils \
    linux-headers \
    krb5-dev \
    pcre2-dev \
    sqlite-dev \
    gettext-dev \
    gmp-dev \
    openssl-dev \
    c-client \
    imap-dev \
    icu-dev \
    ldb-dev \
    libldap \
    openldap-dev \
    oniguruma-dev \
    tidyhtml-dev \ 
    libzip-dev"
ENV PHP_BUILD_DEPS=$PHP_BUILD_DEPS

####################################
#       构建二进制文件             #
####################################
FROM base AS builder

# ***** 安装依赖 *****
RUN set -eux && \
   # 修改源地址
   sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
   # 更新源地址并更新系统软件
   apk update && apk upgrade && \
   # 安装依赖包
   apk add --no-cache --clean-protected $BUILD_DEPS $PHP_BUILD_DEPS && \
   rm -rf /var/cache/apk/* && \
   # 更新时区
   ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
   # 更新时间
   echo ${TZ} > /etc/timezone && \
   # 创建相关目录
   mkdir -pv ${DOWNLOAD_SRC} ${PHP_DIR} && \
   # 创建用户和用户组
   addgroup -g 32548 -S nginx && \
   adduser -S -D -H -u 32548 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx


# ##############################################################################
# ***** 下载源码包 *****  
RUN set -eux && \
    wget --no-check-certificate https://github.com/php/php-src/archive/refs/tags/php-${PHP_VERSION}.tar.gz \
    -O ${DOWNLOAD_SRC}/php-${PHP_VERSION}.tar.gz && \
    wget --no-check-certificate https://pecl.php.net/get/redis-${REDIS_VERSION}.tgz \
    -O ${DOWNLOAD_SRC}/redis-${REDIS_VERSION}.tgz && \
    wget --no-check-certificate https://pecl.php.net/get/swoole-${SWOOLE_VERSION}.tgz \
    -O ${DOWNLOAD_SRC}/swoole-${SWOOLE_VERSION}.tgz && \
    wget --no-check-certificate https://pecl.php.net/get/mongodb-${MONGODB_VERSION}.tgz \
    -O ${DOWNLOAD_SRC}/mongodb-${MONGODB_VERSION}.tgz && \
    cd ${DOWNLOAD_SRC} && tar xvf php-${PHP_VERSION}.tar.gz -C ${DOWNLOAD_SRC} && \
    tar zxf redis-${REDIS_VERSION}.tgz -C ${DOWNLOAD_SRC} && \
    tar zxf swoole-${SWOOLE_VERSION}.tgz -C ${DOWNLOAD_SRC} && \
    tar zxf mongodb-${MONGODB_VERSION}.tgz -C ${DOWNLOAD_SRC}

# ***** 安装PHP *****
RUN set -eux && \
    cd ${DOWNLOAD_SRC}/php-src-php-${PHP_VERSION} && \
    ./buildconf --force && \
    ./configure ${PHP_BUILD_CONFIG} && \
    make -j$(($(nproc)+1)) && make -j$(($(nproc)+1)) install && \
    cd ${DOWNLOAD_SRC}/redis-${REDIS_VERSION} && \
    /data/php/bin/phpize && ./configure --with-php-config=/data/php/bin/php-config && \
    make -j$(($(nproc)+1)) && make -j$(($(nproc)+1)) install && \
    cd ${DOWNLOAD_SRC}/swoole-${SWOOLE_VERSION} && \
    /data/php/bin/phpize && ./configure --with-php-config=/data/php/bin/php-config && \
    make -j$(($(nproc)+1)) && make -j$(($(nproc)+1)) install && \
    cd ${DOWNLOAD_SRC}/mongodb-${MONGODB_VERSION} && \
    /data/php/bin/phpize && ./configure --with-php-config=/data/php/bin/php-config && \
    make -j$(($(nproc)+1)) && make -j$(($(nproc)+1)) install

##########################################
#         构建最新的镜像                  #
##########################################
FROM base
# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=C.UTF-8
ENV LANG=$LANG

ARG PKG_DEPS="\
    zsh \
    bash \
    bash-doc \
    bash-completion \
    bind-tools \
    iproute2 \
    git \
    vim \
    tzdata \
    curl \
    wget \
    lsof \
    tar \
    zip \
    unzip \
    ca-certificates \
    geoip-dev \
    openssl-dev \
    pcre-dev \
    zlib-dev"
ENV PKG_DEPS=$PKG_DEPS

ARG PHP_BUILD_DEPS="\
    ca-certificates \
    openssl \
    tar \
    xz \
    bison \
    readline \
    readline-dev \
    libxslt \
    libxslt-dev \
    libxml2 \
    libxml2-dev \
    openssl \
    openssl-dev \
    bzip2 \
    bzip2-dev \
    curl \
    curl-dev \
    freetype \
    freetype-dev \
    libpng \
    libpng-dev \
    libwebp \
    libwebp-dev \
    libjpeg-turbo \
    libjpeg-turbo-dev \
    libsodium \
    libsodium-dev \
    argon2-dev \
    coreutils \
    linux-headers \
    krb5-dev \
    pcre2-dev \
    sqlite-dev \
    gettext-dev \
    gmp-dev \
    openssl-dev \
    c-client \
    imap-dev \
    icu-dev \
    ldb-dev \
    libldap \
    openldap-dev \
    oniguruma-dev \
    tidyhtml-dev \ 
    libzip-dev"
ENV PHP_BUILD_DEPS=$PHP_BUILD_DEPS

# ***** 安装依赖 *****
RUN set -eux && \
   # 修改源地址
   sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
   # 更新源地址并更新系统软件
   apk update && apk upgrade && \
   # 安装依赖包
   apk add --no-cache --clean-protected $PKG_DEPS $PHP_BUILD_DEPS && \
   rm -rf /var/cache/apk/* && \
   # 更新时区
   ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
   # 更新时间
   echo ${TZ} > /etc/timezone && \
   # 更改为zsh
   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true && \
   sed -i -e "s/bin\/ash/bin\/zsh/" /etc/passwd && \
   sed -i -e 's/mouse=/mouse-=/g' /usr/share/vim/vim*/defaults.vim && \
   /bin/zsh

# 拷贝文件
COPY --from=builder /data /data

# ***** 容器信号处理 *****
STOPSIGNAL SIGQUIT

# ***** 监听端口 *****
EXPOSE 9000/TCP

# ***** 工作目录 *****
WORKDIR /data/php

# ***** 创建用户和用户组 *****
RUN set -eux && \
    addgroup -g 32548 -S nginx && \
    adduser -S -D -H -u 32548 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx && \
    cp -rf /root/.oh-my-zsh /data/php/.oh-my-zsh && \
    cp -rf /root/.zshrc /data/php/.zshrc && \
    sed -i '5s#/root/.oh-my-zsh#/data/php/.oh-my-zsh#' /data/php/.zshrc && \
    chmod -R 775 /data/php && \
    mkdir -pv /data/php/etc/php-fpm.d/ /data/php/var/run/ /data/php/var/log/ && \
    ln -sf ${PHP_DIR}/bin/* /usr/bin/ && \
    ln -sf ${PHP_DIR}/sbin/* /usr/sbin/ && \
    rm -rf /var/cache/apk/*
    
# 拷贝文件
COPY ["./conf/php/etc/php.ini", "/data/php/etc/php.ini"]
COPY ["./conf/php/etc/php-fpm.conf", "/data/php/etc/php-fpm.conf"]
COPY ["./conf/php/etc/php-fpm.d/www.conf", "/data/php/etc/php-fpm.d/www.conf"]

# 启动命令
CMD ["php-fpm", "--nodaemonize", "--fpm-config", "/data/php/etc/php-fpm.conf"]
