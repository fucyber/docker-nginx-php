FROM alpine:3.11

# RUN ALPINE_VERSION=`cat /etc/alpine-release | cut -d'.' -f-2` && \
#     wget -O /etc/apk/keys/php-alpine.rsa.pub https://packages.whatwedo.ch/php-alpine.rsa.pub && \
#     echo "@php https://packages.whatwedo.ch/php-alpine/v$ALPINE_VERSION/php-7.4" >> /etc/apk/repositories && \
#     apk update && \
#     apk --no-cache add

ENV TZ='Asia/Bangkok'

# ADD https://dl.bintray.com/php-alpine/key/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub
# RUN apk --update add ca-certificates wget && \
#     echo "https://dl.bintray.com/php-alpine/v3.12/php-7.4" >> /etc/apk/repositories

RUN ALPINE_VERSION=`cat /etc/alpine-release | cut -d'.' -f-2` && \
    wget -O /etc/apk/keys/php-alpine.rsa.pub https://packages.whatwedo.ch/php-alpine.rsa.pub && \
    echo "@php https://packages.whatwedo.ch/php-alpine/v$ALPINE_VERSION/php-7.4" >> /etc/apk/repositories

RUN apk --no-cache add curl nano

RUN apk add tzdata && \
    cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "${TZ}" > /etc/timezone && \
    apk del tzdata


# Create user
RUN adduser -D -u 1000 -g 1000 -s /bin/sh www-data && \
    mkdir -p /var/www && \
    chown -R www-data:www-data /var/www

# Install tini - 'cause zombies - see: https://github.com/ochinchina/supervisord/issues/60
# (also pkill hack)
RUN apk add --no-cache --update tini

# Install a golang port of supervisord
COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/bin/supervisord

# Install nginx & gettext (envsubst)
# Create cachedir and fix permissions
RUN apk add --no-cache --update \
    gettext \
    nginx && \
    mkdir -p /var/cache/nginx && \
    mkdir -p /var/tmp/nginx && \
    chown -R www-data:www-data /var/cache/nginx && \
    chown -R www-data:www-data /var/lib/nginx && \
    chown -R www-data:www-data /var/tmp/nginx && \
    chgrp -R www-data /var/lib/nginx/tmp

# Install PHP/FPM + Modules
RUN apk add --no-cache --update \
    php \
    # php-apcu \
    php-bcmath \
    php-bz2 \
    php-cgi \
    php-ctype \
    php-curl \
    php-dom \
    php-fpm \
    php-ftp \
    php-gd \
    php-iconv \
    php-json \
    php-mbstring \
    php-opcache \
    php-openssl \
    php-pcntl \
    php-pdo \
    php-pdo_mysql \
    php-phar \
    # php-redis \
    php-session \
    php-simplexml \
    php-tokenizer \
    # php-xdebug \
    php-xml \
    php-xmlwriter \
    php-zip \
    php-zlib \
    # php-mongodb \
    php-mysqli \
    php-fileinfo \
    php-pdo_pgsql \
    php-pgsql \
    # php-libpq-dev \
    php-sqlite3

# RUN docker-php-ext-install pdo pdo_pgsql pgsql libpq-dev postgresql-dev
# RUN apt-get update && apt-get install -y libpq-dev
# RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql
# RUN docker-php-ext-install pdo pdo_pgsql
# # RUN apt-get update && apt-get install -y postgresql-dev

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --quiet --install-dir=/usr/bin --filename=composer && \
    rm composer-setup.php

COPY ./supervisord.conf /supervisord.conf
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./docker-entrypoint.sh /docker-entrypoint.sh


RUN chmod -R 777  /var/lib/nginx/tmp

# Nginx on :80
EXPOSE 80
WORKDIR /var/www
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]
