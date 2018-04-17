#!/bin/sh
set -e

# CONSTANTS
readonly TMP_PHP_MODS_LIST_FILE="/tmp/php_mods.list"

# FUNCTIONS
eprint()
{
    msg="${*}"
    printf "%b\n" "$msg"
}

create_tmp_php_mods_list()
{
    if result=$(php -m 2>&1 > "$TMP_PHP_MODS_LIST_FILE"); then
        eprint "\e[0;36m [DEBUG] Created: $TMP_PHP_MODS_LIST_FILE \e[0m"
    else
        status=$?
        eprint "\e[41;1;37m [ERROR] CODE: $status\n MESSAGE: $result \e[0m"
        exit $((status));
    fi

    return 0
}

remove_tmp_php_mods_list()
{
    if [ -f "$TMP_PHP_MODS_LIST_FILE" ]; then
        printf "\e[0;36m [DEBUG] "
        rm -v "$TMP_PHP_MODS_LIST_FILE"
        printf "\e[0m"
    fi
}

is_installed()
{
    if result=$(grep "$1" /tmp/php_mods.list 2>&1); then
        eprint "\e[0;33m [WARNING] $result is already installed. It won't be installed again :)\e[0m"
        return 0
    else
        status=$?
        if [ $status -eq 1 ]; then
            return $((status))
        else
            eprint "\e[41;1;37m [ERROR] CODE: $status\n MESSAGE: $result \e[0m"
            exit $((status));
        fi
    fi
}

# Write installed module in a temp file for easier search
create_tmp_php_mods_list

# Get extension list parameter
AddPhpExt="$*"

# Do the job :)
for ext in $AddPhpExt; do
    if ! is_installed "$ext"; then
        eprint "\e[0;32m [INFO] Gonna try to install $ext. \e[0m"

        case "$ext" in
            pdo_mysql )
                # echo "pdo_mysql"
                docker-php-ext-install pdo_mysql
                ;;
            mysqli )
                # echo "mysqli"
                docker-php-ext-install mysqli
                ;;
            zip )
                # echo "zip"
                apk add --no-cache zlib-dev \
                && docker-php-ext-install zip
                ;;
            mcrypt )
                # echo "mcrypt"
                apk add --no-cache libmcrypt libmcrypt-dev \
                && docker-php-ext-install mcrypt
                ;;
            intl )
                # echo "intl"
                apk add --no-cache libintl icu icu-dev \
                && docker-php-ext-install intl
                ;;
            bcmath )
                # echo "bcmath"
                docker-php-ext-install bcmath
                ;;
            soap )
                # echo "soap"
                apk add --no-cache libxml2-dev \
                && docker-php-ext-install soap
                ;;
            pdo_pgsql )
                # echo "pdo_pgsql"
                apk add --no-cache postgresql-dev \
                && docker-php-ext-install pdo_pgsql
                ;;
            gd )
                # echo "gd"
                apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev \
                && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
                && docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" gd
                ;;
            memcached )
                # echo "memcached"
                apk add --no-cache libmemcached libmemcached-dev zlib-dev cyrus-sasl-dev git \
                && docker-php-source extract \
                && git clone --branch 2.2.0 https://github.com/php-memcached-dev/php-memcached.git /usr/src/php/ext/memcached/ \
                && docker-php-ext-configure memcached \
                && docker-php-ext-install memcached \
                && docker-php-source delete
                ;;
            apcu )
                # echo "apcu"
                docker-php-source extract \
                && apk add --no-cache --virtual .phpize-deps-configure $PHPIZE_DEPS \
                && pecl install apcu \
                && docker-php-ext-enable apcu \
                && apk del .phpize-deps-configure \
                && docker-php-source delete
                ;;
            redis )
                # echo "redis"
                export PHPREDIS_VERSION="3.1.6"
                docker-php-source extract \
                && curl -L -o /tmp/redis.tar.gz "https://github.com/phpredis/phpredis/archive/${PHPREDIS_VERSION}.tar.gz" \
                && tar xfz /tmp/redis.tar.gz \
                && rm -r /tmp/redis.tar.gz \
                && mv phpredis-$PHPREDIS_VERSION /usr/src/php/ext/redis \
                && docker-php-ext-install redis \
                && docker-php-source delete
                ;;
            imagick )
                # echo "imagick"
                apk add --update --no-cache autoconf g++ imagemagick-dev pcre-dev libtool make \
                && pecl install imagick \
                && docker-php-ext-enable imagick \
                && apk del autoconf g++ libtool make pcre-dev
                ;;
            ssh2 )
                # echo "ssh2"
                apk add --update --no-cache autoconf g++ libtool make pcre-dev libssh2 libssh2-dev \
                && pecl install ssh2-1 \
                && docker-php-ext-enable ssh2 \
                && apk del autoconf g++ libtool make pcre-dev
                ;;
            ? | *) # If extension not in cases
                eprint "\e[0;33m [WARNING] extension $ext is not present in case list \e[0m";
                eprint "\e[41;1;37m\e[7m [IMPORTANT] Please check extension name for: $ext \e[0m"
                ;;
        esac
    fi
done

# Delete php_mods_list temp file
remove_tmp_php_mods_list