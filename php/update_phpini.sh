#!/bin/sh
set -e

eprint()
{
    msg="${*}"
    printf '%b\n' "$msg"
}

list_keys()
{
    printf "--------- %*s-------------\\n" "25"
    printf "|\\e[1;33mINI-KEY\\e[0m| %*s|\\e[1;36mENVVAR-NAME\\e[0m|\\n" "25"
    printf "--------- %*s-------------\\n" "25"
    printenv |awk -F '=' '/^PHPINI_/ {
        ininame = substr(tolower($1), 8);
        gsub("__", ".", ininame);
        printf "\033[0;33m%s \033[0;36m%42s\033[0m\n", ininame, $1;
    }'
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
    if [ ! -z "$2" ]; then
        ## Met \devant les caractère spéciaux
        value=$(printf '%s' "$2" | sed 's/[#\]/\\\0/g')
        name="$1"
        success_msg="\\e[0;32m Set PHP ${name} = ${value} \\e[0m"

        if grep "${name} = " "${PhpIniPath}" > /dev/null; then
            sed -i "s#\\;\\?\\s\\?${name} = .*#${name} = ${value}#" "${PhpIniPath}" \
                && eprint "$success_msg";
        else
            echo "${name} = ${value}" >> "${PhpIniPath}" \
                && eprint "$success_msg";
        fi
    else
        if grep "${name} = " "${PhpIniPath}" > /dev/null; then
            # shellcheck disable=SC2154
            sed -i "s#\\;\\?\\s\\?${name} = ${value}#; ${name} = ${value}#" "${PhpIniPath}" \
            && eprint "${name} is comment";
        fi
    fi
}

usage()
{
    eprint "\\e[1;32m[Synopsis]\\e[0m"
    eprint "    Modify php.ini values according to EnvVars values"
    eprint "\\e[1;32m[Usage]\\e[0m"
    eprint "    $0 [-c] [-p 'phpini-path']"
    eprint "\\e[1;32m[Options]\\e[0m"
    eprint "    -h  print this help and exit"
    eprint "    -l  list ini_keys and exit"
    eprint "    -p   </path/to/php.ini>   set php.ini path \\e[0;33m(default: /etc/php.ini)\\e[0m"
    eprint "    -c  force php.ini creation if does not exists"
    eprint "\\e[1;32m[Examples]\\e[0m"
    eprint "       PHPINI_DATE_TIMEZONE='Europe/Paris' $0"
    eprint "       $0 -p /etc/php.ini"
    eprint "       $0 -c -p '/usr/local/etc/php/php.ini'"

    exit_status=${1:-"0"}
    exit $((exit_status))
}

Create="false";
## OPTIONS
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts ":hlp:c" opt; do
    case "$opt" in
        h) # Print usage() & exit
            usage 0;
            ;;
        l) # Print php.ini keys list
            list_keys; exit 0;
            ;;
        p) # Set PhpIniPath
            PhpIniPath="$OPTARG"
            ;;
        c) # Set Create
            Create="true";
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
eprint "\\e[32;1m [START]: $0 \\e[0m"

# shellcheck disable=SC1004
phpini_list=$(printenv | awk -F '=' '/^PHPINI_/ {
        ininame = substr(tolower($1), 8);
        gsub("__", ".", ininame);
        printf "%s=%s\n", ininame, $2;
    }')
[ -z "$phpini_list" ] && eprint "\\e[31;1m [ERROR] PHPINI list in environment variables is empty\\e[0m" && exit 0;

export phpini_list

## Default Value for "$PhpIniPath"
PhpIniPath=${PhpIniPath:-"/etc/php.ini"}
export PhpIniPath

## Create empty php.ini if doesn't exists and $Create=true
if [ ! -f "$PhpIniPath" ]; then
    [ "$Create" != "true" ] && the_end "\\e[41;1;37m [ERROR] File not found: ${PhpIniPath} \\e[0m" 40;

    if ! result=$(touch "$PhpIniPath" 2>&1); then
        status=$?
        eprint "\\e[41;1;37m [ERROR:${status}] ${result} \\e[0m" && exit $((status));
    fi
    eprint "\\e[0;32m Succesfully created new file: ${PhpIniPath} \\e[0m"
fi

for phpini_item in $phpini_list; do
    # shellcheck disable=SC2154
    update_line_if $(echo $phpini_item |tr "=" " ")
done

# Exit Success
eprint "\\e[32;1m [END] Executed: $0 :) \\e[0m" && exit 0;
