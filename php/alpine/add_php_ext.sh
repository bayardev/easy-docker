#!/bin/sh
# shellcheck disable=SC2034

set -a
# CONSTANTS
readonly TMP_PHP_MODS_LIST_FILE="/tmp/php_mods.list"
## COLORS
CLR0='\e[0m'
CLRh1='\e[1;32m'
CLRh2='\e[32m'
CLRspan='\e[33m'
CLRwarning='\e[1;33m'
CLRerror='\e[41;1;37m'
CLRinfo='\e[32m'
CLRnotice='\e[1;36m'
CLRstart=${CLRh1}
CLRend=${CLRstart}
CLRstop='\e[1;31m'
CLRDebug='\e[36m'
set +a

# FUNCTIONS
eprint()
{
    msg="${*}"

    FirstWord=$(printf '%b' "$msg" | grep -oE '^\[?(ERROR|WARNING|INFO|NOTICE|START|END|STOP)\]?');
    if [ -n "$FirstWord" ]; then
        nameCLR="CLR"$(printf '%s' "$FirstWord" | tr '[:upper:]' '[:lower:]' | tr -d '[]')
        eval nameCLR="\${$nameCLR}"
        printf "%b" "$nameCLR"
    fi

    printf '%b%b\n' "$msg" "$CLR0"
}

# shellcheck disable=SC2086
the_end()
{
    ExitStatus=${1:-"0"}

    if [ $ExitStatus -eq 0 ]; then
        eprint "[END] Executed: $0 :)"
    else
        eprint "[STOP] execution of $0 , because error $ExitStatus"
    fi

    exit $((ExitStatus))
}

# Write installed module in a temp file for easier search
create_tmp_php_mods_list()
{
    if ! [ -f "$TMP_PHP_MODS_LIST_FILE" ]; then
        if result=$(php -m 2>&1 > "$TMP_PHP_MODS_LIST_FILE"); then
            eprint "[DEBUG] Created: $TMP_PHP_MODS_LIST_FILE"
        else
            status=$?
            eprint "[ERROR] CODE: $status\\n MESSAGE: $result"
            the_end $((status));
        fi
    fi

    return 0
}

remove_tmp_php_mods_list()
{
    if [ -f "$TMP_PHP_MODS_LIST_FILE" ]; then
        printf '%b[DEBUG] ' "$CLRDebug"
        rm -v "$TMP_PHP_MODS_LIST_FILE"
        printf "%b" "$CLR0"
    fi
}

is_installed()
{
    if result=$(grep "$1" /tmp/php_mods.list 2>&1); then
        eprint "[WARNING] $result is already installed. It won't be installed again :)"
        return 0
    else
        status=$?
        if [ $status -eq 1 ]; then
            return $((status))
        else
            eprint "[ERROR] CODE: $status\\n MESSAGE: $result"
            the_end $((status));
        fi
    fi
}

php_version_compare()
{
    CompareOperator=$1;
    VersionCompare=$2;
    Result=$(php -r 'echo version_compare(PHP_VERSION, "'"${VersionCompare}"'", "'"${CompareOperator}"'") ? "TRUE" : "";')

    test -n "${Result}";
}

php_version()
{
    Result=$(php -r 'echo PHP_VERSION;')
    if [ -n "$1" ]; then
        Result=$(echo "$Result" | cut -d '.' -f 1,2)
    fi

    echo "$Result"
}

usage()
{
    eprint "\\e[1;32m[Synopsis]\\e[0m"
    eprint "    Install php extensions"
    eprint "\\e[1;32m[Usage]\\e[0m"
    eprint "    $0 <ext_name> [more_ext] [...]"
    eprint "\\e[1;32m[Options]\\e[0m"
    eprint "    -h  print this help and exit"
    eprint "\\e[1;32m[Examples]\\e[0m"
    eprint "       $0 sockets pdo_mysql zip"

    exit_status=${1:-"0"}
    exit $((exit_status))
}

Create="false";
## OPTIONS
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts ":h" opt; do
    case "$opt" in
        h) # Print usage() & exit
            usage 0;
            ;;
        :) # If Option require an argument and none given, Exit with Error
            eprint "\\e[41;1;37m [ERROR] Option '-$OPTARG' require a value \\e[0m"; usage 40;
            ;;
        ? | *) # If not valid Option : print Warning
            eprint "\\e[43;1;90m [WARNING] Option '-$OPTARG' not Valid ! \\e[0m"; usage 40;
            ;;
    esac
done
shift "$((OPTIND-1))"

# Print START script execution
eprint "[START]: $0"

# Get PHP Version
PHPVersion=$(php_version "short")

# Get extension list parameter
AddPhpExt="$*"

# Do the job :)
# shellcheck disable=SC2086
for ext in $AddPhpExt; do
    create_tmp_php_mods_list
    if ! is_installed "$ext"; then
        eprint "[INFO] Gonna try to install ${ext}."
        case "$ext" in
            sockets )
                # echo "sockets"
                docker-php-ext-install sockets
                ;;
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
                if [ "$PHPVersion" = "7.2" ]; then
                    apk add --no-cache libzip-dev
                    docker-php-ext-configure zip --with-libzip
                    docker-php-ext-install zip
                else
                    apk add --no-cache zlib-dev \
                    && docker-php-ext-install zip
                fi
                ;;
            mcrypt )
                # echo "mcrypt"
                if [ "$PHPVersion" = "7.2" ]; then
                    eprint "[WARNING] Cannot install 'mcrypt' in PHP 7.2; Since PHP 7.2 the mcrypt extension doesn't exists anymore"
                else
                    apk add --no-cache libmcrypt libmcrypt-dev \
                    && docker-php-ext-install mcrypt
                fi
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
                if [ "$PHPVersion" = "5.6" ]; then
                    apk add --no-cache libmemcached libmemcached-dev zlib-dev cyrus-sasl-dev git \
                    && docker-php-source extract \
                    && git clone --branch 2.2.0 https://github.com/php-memcached-dev/php-memcached.git /usr/src/php/ext/memcached/ \
                    && docker-php-ext-configure memcached \
                    && docker-php-ext-install memcached \
                    && docker-php-source delete
                else
                    export MEMCACHED_DEPS="zlib-dev libmemcached-dev cyrus-sasl-dev"
                    apk add --no-cache --update libmemcached libmemcached-libs zlib \
                    && apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS \
                    && apk add --no-cache --update --virtual .memcached-deps $MEMCACHED_DEPS \
                    && yes 'no' | pecl install -fo memcached \
                    && docker-php-ext-enable memcached \
                    && rm -rf /usr/share/php7 \
                    && rm -rf /tmp/* \
                    && apk del .memcached-deps .phpize-deps
                fi
                ;;
            memcache )
                # echo "memcache"
                if [ "$PHPVersion" = "5.6" ]; then
                    docker-php-source extract \
                    && apk add --no-cache --virtual .phpize-deps-configure $PHPIZE_DEPS \
                    && apk add --update --no-cache openssh-client make grep autoconf gcc libc-dev zlib-dev \
                    && yes | pecl install -fo memcache \
                    && docker-php-ext-enable memcache \
                    && apk del .phpize-deps-configure \
                    && docker-php-source delete
                else
                    eprint "[WARNING] Cannot install 'memcache' in PHP 7.x ; Please install instead memcached"
                fi
                ;;
            apcu )
                # echo "apcu"
                docker-php-source extract \
                && apk add --no-cache --virtual .phpize-deps-configure $PHPIZE_DEPS \
                && yes | pecl install -fo apcu \
                && docker-php-ext-enable apcu \
                && apk del .phpize-deps-configure \
                && docker-php-source delete
                ;;
            redis )
                # echo "redis"
                if [ "$PHPVersion" = "5.6" ]; then
                    if [ -z "$PHPREDIS_VERSION" ]; then
                        export PHPREDIS_VERSION="3.1.6"
                    fi; \
                    docker-php-source extract \
                    && curl -L -o /tmp/redis.tar.gz "https://github.com/phpredis/phpredis/archive/${PHPREDIS_VERSION}.tar.gz" \
                    && tar xfz /tmp/redis.tar.gz \
                    && rm -r /tmp/redis.tar.gz \
                    && mv phpredis-$PHPREDIS_VERSION /usr/src/php/ext/redis \
                    && docker-php-ext-install redis \
                    && docker-php-source delete
                else
                    docker-php-source extract \
                    && apk add --no-cache --virtual .phpize-deps-configure $PHPIZE_DEPS \
                    && if [ -n "$PHPREDIS_VERSION" ]; then
                        yes 'no' | pecl install -fo redis-${PHPREDIS_VERSION}
                    else
                        yes 'no' | pecl install -fo redis 
                    fi \
                    && docker-php-ext-enable redis \
                    && apk del .phpize-deps-configure \
                    && docker-php-source delete
                fi
                ;;
            imagick )
                # echo "imagick"
                export IMAGICK_DEPS="autoconf g++ pcre-dev libtool make"
                apk add --update --no-cache imagemagick-dev \
                && apk add --no-cache --update --virtual .imagick-deps $IMAGICK_DEPS \
                && yes 'autodetect' | pecl install -fo imagick \
                && docker-php-ext-enable imagick \
                && apk del .imagick-deps
                ;;
            ssh2 )
                # echo "ssh2"
                export SSH2_DEPS="autoconf g++ libtool make pcre-dev"
                apk add --update --no-cache libssh2 libssh2-dev \
                && apk add --no-cache --update --virtual .ssh2-deps $SSH2_DEPS \
                && yes 'autodetect' | pecl install -fo ssh2-1 \
                && docker-php-ext-enable ssh2 \
                && apk del .ssh2-deps
                ;;
            opcache )
                docker-php-ext-install opcache
                ;;
            xdebug )
                apk add --no-cache $PHPIZE_DEPS \
                && pecl install xdebug \
                && docker-php-ext-enable xdebug
                ;;
            ? | *) # If extension not in cases
                eprint "[WARNING] extension $ext is not present in case list";
                eprint "[IMPORTANT] Please check extension name for: $ext"
                ;;
        esac
    fi
done

# Delete php_mods_list temp file
remove_tmp_php_mods_list

# Exit Success
the_end;