#!/bin/sh
set -e

# PHP.INI LIST
readonly phpini_list="short_open_tag
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

eprint()
{
    msg="${*}"
    printf "%b\n" "$msg"
}

list_keys()
{
    eprint "--------- -------------"
    eprint "|\e[1;33mINI-KEY\e[0m| |\e[1;36mENVVAR-NAME\e[0m|"
    eprint "--------- -------------"
    for phpini_key in $phpini_list; do
        varname="PHP_"$(echo "$phpini_key" |tr "[:lower:]" "[:upper:]" |tr "." "_")
        eprint "\e[0;33m${phpini_key} \e[0;36m${varname}\e[0m"
    done
}

the_end()
{
    msg="$1"
    exit_status=${2:-"0"}

    eprint "$msg"
    [ -z "$3" ] && eprint "$0 -h for help";
    exit $((exit_status))
}

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

usage()
{
    eprint "\e[1;32m[Synopsis]\e[0m"
    eprint "    Modify php.ini values according to EnvVars values"
    eprint "\e[1;32m[Usage]\e[0m"
    eprint "    $0 [-c] [-p 'phpini-path']"
    eprint "\e[1;32m[Options]\e[0m"
    eprint "    -h  print this help and exit"
    eprint "    -l  list ini_keys and exit"
    eprint "    -p </path/to/php.ini>   set php.ini path \e[0;33m(default: /etc/php.ini)\e[0m"
    eprint "    -c  force php.ini creation if doesn't exists"
    eprint "\e[1;32m[Examples]\e[0m"
    eprint "       $0"
    eprint "       $0 -p /etc/php.ini"
    eprint "       $0 -c -p '/usr/local/etc/php/php.ini'"

    exit_status=${1:-"0"}
    exit $((exit_status))
}

# Print START script execution
eprint "\e[32;1m [START]: $0 \e[0m\n"

Create="false";
## OPTIONS
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts ":hlp:c" opt; do
    case "$opt" in
        h) # Print usage() & exit
            usage 0;
            ;;
        l) # Print php.ini keys list
            list_keys |column -t && exit 0;
            ;;
        p) # Set PhpIniPath
            PhpIniPath="$OPTARG"
            ;;
        c) # Set Create
            Create="true";
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
## Create empty php.ini if doesn't exists and $Create=true
if [ ! -f "$PhpIniPath" ]; then
    [ "$Create" != "true" ] && the_end "\e[41;1;37m [ERROR] File not found: ${PhpIniPath} \e[0m" 40;

    if ! result=$(touch "$PhpIniPath" 2>&1); then
        status=$?
        eprint "\e[41;1;37m [ERROR:${status}] ${result} \e[0m" && exit $((status));
    fi
    eprint "\e[0;32m Succesfully created new file: ${PhpIniPath} \e[0m"
fi

for phpini_key in $phpini_list; do
    varname="PHP_"$(echo "$phpini_key" |tr "[:lower:]" "[:upper:]" |tr "." "_")
    eval envvar="\${$varname}"
    # shellcheck disable=SC2154
    update_line_if "$envvar" "$phpini_key"
done

# Exit Success
eprint "\e[32;1m [END] Executed: $0 :) \e[0m" && exit 0;
