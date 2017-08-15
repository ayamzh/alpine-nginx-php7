#基础镜像
FROM alpine:latest

MAINTAINER ayamzh "ayamzh@126.com"

#时区变量
ENV TIMEZONE="Asia/Shanghai"

#设置语言 更新软件  设置时区
RUN export LANG=zh_CN.UTF-8 && apk update && apk upgrade && apk add --update tzdata
RUN echo $TIMEZONE > /etc/timezone && ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime


#安装nginx supervisor 等软件
RUN apk add --update nginx \
openssh \
supervisor \
git \
curl \
curl-dev \
make \
zlib-dev \
build-base \
zsh \
vim \
vimdiff \
wget \
sudo

#安装PHP7
RUN apk add --update php7 \
php7-dev \
php7-mysqlnd \
php7-pdo_mysql \
php7-mysqli \
php7-mcrypt \
php7-mbstring \
php7-openssl \
php7-json \
php7-redis \
php7-mysqli \
php7-gd \
php7-fpm \
php7-bcmath \
php7-tokenizer \
php7-gettext \
php7-iconv \
php7-curl \
php7-pear \
php7-phar \
php7-memcached \
php7-opcache \
php7-pcntl \
php7-posix \
php7-sockets

#配置opcache
RUN echo -e "[opcache] \n\
zend_extension=opcache.so \n\
opcache.memory_consumption=128 \n\
opcache.interned_strings_buffer=8 \n\
opcache.max_accelerated_files=4000 \n\
opcache.revalidate_freq=60 \n\
opcache.fast_shutdown=1 \n\
opcache.enable_cli=1" > /etc/php7/conf.d/00_opcache.ini

#安装mongodb扩展(和kafka所需类库冲突)?
RUN apk add openssl-dev && \
pecl install mongodb && \
echo extension=mongodb.so > /etc/php7/conf.d/mongodb.ini && \
pecl clear-cache

#安装kafka扩展
RUN apk add libssl1.0 librdkafka-dev && \
pecl install rdkafka && \
echo extension=rdkafka.so > /etc/php7/conf.d/rdkafka.ini && \
pecl clear-cache

#安装couchbase扩展必须删除openssl-dev和libcouchbase-dev冲突
RUN apk del openssl-dev  && \
apk add libcouchbase-dev  && \
pecl install couchbase-2.2.3 && \
echo extension=couchbase.so > /etc/php7/conf.d/couchbase.ini && \
pecl clear-cache

#安装msgpack扩展
RUN pecl install msgpack && \
echo extension=msgpack.so > /etc/php7/conf.d/msgpack.ini && \
pecl clear-cache

#安装jsond扩展
RUN pecl install jsond && \
echo extension=jsond.so > /etc/php7/conf.d/jsond.ini && \
pecl clear-cache

#安装yar扩展
RUN pecl install yar && \
echo extension=yar.so > /etc/php7/conf.d/yar.ini && \
echo yar.packager=json >> /etc/php7/conf.d/yar.ini && \
pecl clear-cache

#安装yac扩展
RUN pecl install yac-2.0.2 && \
echo -e "[yac] \n\
extension=yac.so \n\
yac.enable=1 \n\
yac.keys_memory_size=4M \n\
yac.values_memory_size=64M \n\
yac.compress_threshold=-1 \n\
yac.enable_cli=0" > /etc/php7/conf.d/yac.ini && \
pecl clear-cache

#安装event扩展?
RUN apk add libevent-dev && \
pecl install event && \
echo extension=event.so > /etc/php7/conf.d/event.ini && \
pecl clear-cache

#安装swoole扩展
#RUN pecl install swoole && \
#echo extension=swoole.so > /etc/php7/conf.d/swoole.ini && \
#pecl clear-cache

#安装composer
#RUN curl -sS https://getcomposer.org/installer | php && \
#mv composer.phar /usr/local/bin/composer

#上传配置文件
COPY config/composer.phar /usr/local/bin/composer
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/zzz_custom.conf
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENV SHELL="/bin/zsh" \
    LOG_PATH="/data/log/" \
    RUN_PATH="/data/run/" \
    CONF_PATH="/data/conf/" \
    NGINX_LOG_PATH="/data/conf/nginx/conf.d/"

RUN mkdir -p -m 755 $LOG_PATH  && \
mkdir -p -m 755 $RUN_PATH  && \
mkdir -p -m 755 $NGINX_LOG_PATH

EXPOSE 80 443

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
