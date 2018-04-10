#!/bin/sh
set -e

eprint()
{
    msg="${*}"
    printf "%b\n" "$msg"
}

usage()
{
    eprint "\e[43;1;37m[Synopsis]\e[0m"
    eprint "   Modify php.ini values according to EnvVars values"
    eprint "   "
    eprint "\e[43;1;37m[Usage]\e[0m"
    eprint "   $0 [-p 'phpini-path']"
    eprint "\e[0;32m Examples: \e[0m"
    eprint "       $0"
    eprint "       $0 -p /etc/php.ini"
    eprint "\e[0;32m Default Values: \e[0m"
    eprint "   phpini-path : /etc/php.ini"

    exit_status=${1:-"0"}
    exit $((exit_status))
}

## OPTIONS
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts ":hp:" opt; do
    case "$opt" in
        h) # Print usage() & exit
            usage 0;
            ;;
        p) # Set PhpIniPath
            PhpIniPath="$OPTARG"
            ;;
        :) # If Option require an argument and none given, Exit with Error
            eprint "\e[41;1;37m [ERROR] Option '-$OPTARG' require a value \e[0m"; usage 40;
            ;;
        ? | *) # If not valid Option : print Warning
            eprint "\e[43;1;90m [WARNING] Option '-$OPTARG' not Valid ! \e[0m"; usage 40;
            ;;
    esac
done
shift "$((OPTIND-1))"

## Default Value for "$PhpIniPath"
PhpIniPath=${PhpIniPath:-"/etc/php.ini"}
export PhpIniPath
## Create empty php.ini if doesn't exists
if [ ! -f "$PhpIniPath" ]; then
    if ! result=$(touch "$PhpIniPath" 2>&1); then
        status=$?
        eprint "\e[41;1;37m [ERROR:${status}] ${result} \e[0m" && exit $((status));
    fi
    eprint "\e[0;32m Succesfully created new file: ${PhpIniPath} \e[0m"
fi

# PHP Config
php_configs="short_open_tag
output_buffering
open_basedir
max_execution_time
max_input_time
max_input_vars
memory_limit
error_reporting
display_errors
display_startup_errors
log_errors
log_errors_max_len
ignore_repeated_errors
report_memleaks
html_errors
error_log
post_max_size
default_mimetype
default_charset
file_uploads
upload_tmp_dir
upload_max_filesize
max_file_uploads
allow_url_fopen
allow_url_include
default_socket_timeout
date.timezone
pdo_mysql.cache_size
pdo_mysql.default_socket
session.save_handler
session.save_path
session.use_strict_mode
session.use_cookies
session.cookie_secure
session.name
session.cookie_lifetime
session.cookie_path
session.cookie_domain
session.cookie_httponly
"
update_line_if()
{
    if [ ! -z "$1" ]; then
        value=$(printf '%s' "$1" | sed 's/[#\]/\\\0/g')
        name="$2"
        success_msg="\e[0;32m Set PHP ${name} = ${value} \e[0m"

        if grep "${name} = " "${PhpIniPath}" > /dev/null; then
            sed -i "s#\;\?\\s\?${name} = .*#${name} = ${value}#" "${PhpIniPath}" \
                && eprint "$success_msg";
        else
            echo "${name} = ${value}" >> "${PhpIniPath}" \
                && eprint "$success_msg";
        fi

    fi
}

for config in $php_configs; do
    varname="PHP_"$(echo "$config" |tr "[:lower:]" "[:upper:]" |tr "." "_")
    eval envvar="\${$varname}"
    # shellcheck disable=SC2154
    update_line_if "$envvar" "$config"
done

# Exit Success
eprint "\e[42;1;37m [END] Executed: $0 :) \e[0m" && exit 0;
