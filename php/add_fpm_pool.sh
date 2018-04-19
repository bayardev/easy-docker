#!/bin/sh
set -ea

## Default Values (CONSTANTS)
readonly DEFAULT_FPM_USER="www-data"
readonly DEFAULT_FPM_CONF_DIR="/usr/local/etc/php-fpm.d"
readonly DEFAULT_TEMPLATE_NAME="pool.conf.tpl"
readonly GET_TEMPLATE_FROM="https://raw.githubusercontent.com/bayardev/easy-docker/master/php/templates"

## COLORS
CLR0="\e[0m"
CLRh1="\e[1;32m"
CLRh2="\e[32m"
CLRspan="\e[33m"
CLRwarn="\e[1;33m"
CLRerr="\e[41;1;37m"
CLRinfo="${CLRh2}"

eprint()
{
    msg="${*}"
    printf "%b${CLR0}\n" "$msg"
}

the_end()
{
    msg="$1"
    exit_status=${2:-"0"}

    eprint "$msg"
    [ -z "$3" ] && eprint "${CLRspan}$0 -h for help";
    exit $((exit_status))
}

get_template()
{
    status=0
    if result=$(curl -sSfLk -o "${TemplatePath}" "${GET_TEMPLATE_FROM}/${TemplateName}" 2>&1); then
        eprint "${CLRinfo}[INFO] ${TemplateName} imported in ${TemplatePath}"
    else
        status=$?
        eprint "${CLRerr}Failed to get ${GET_TEMPLATE_FROM}/${TemplateName}";
        eprint "${CLRerr}[ERROR] ${result}";
    fi

    return $((status))
}

copy_template()
{
    status=0
    if result=$(cp "$TemplatePath" "$DestPath" 2>&1); then
        eprint "${CLRinfo}[INFO] ${DestPath} copied from ${TemplatePath}"
    else
        status=$?
        eprint "${CLRerr}Failed to copy ${TemplatePath} in ${DestPath}";
        eprint "${CLRerr}[ERROR] ${result}";
    fi

    return $((status))
}

usage()
{
    eprint "${CLRh2}[Synopsis]"
    eprint "    Create new php-fpm pool for <app-name> based on template"
    eprint "${CLRh2}[Usage]"
    eprint "   $0 [-u 'user'] [-g 'group'] <app-name>"
    eprint "${CLRh2}[Options]"
    eprint "    -h  print this help and exit"
    eprint "    -u <user>  set Unix user of processes ${CLRspan}(default: '${DEFAULT_FPM_USER}')"
    eprint "    -g <group>  set Unix group of processes ${CLRspan}(If the group is not set, the default user's group will be used)"
    eprint "    -d <fpm-conf-dir>  php-fpm conf dir for pools ${CLRspan}(default: '${DEFAULT_FPM_CONF_DIR}')"
    eprint "    -t <template-name>  pool template-name ${CLRspan}(default: '${DEFAULT_TEMPLATE_NAME}')"
    eprint "${CLRh2}[Examples]"
    eprint "       $0 -u toto myapp"
    eprint "       $0 -u php-fpm -d /etc/php-fpm.d myapp"

    exit_status=${1:-"0"}
    exit $((exit_status))
}

# Print START script execution
eprint "${CLRh1}[START]: $0"

## OPTIONS
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts ":hu:g:d:t:" opt; do
    case "$opt" in
        h) # Print usage() & exit
            usage 0;
            ;;
        u) # Set FpmUser
            FpmUser="$OPTARG"
            ;;
        g) # Set FpmGroup
            FpmGroup="$OPTARG"
            ;;
        d) # Set FpmConfDir
            FpmConfDir="$OPTARG"
            ;;
        t) # Set TemplateName
            TemplateName="$OPTARG"
            ;;
        :) # If Option require an argument and none given, Exit with Error
            eprint "${CLRerr}[ERROR] Option '-$OPTARG' require a value"; usage 40;
            ;;
        ? | *) # If not valid Option : print Warning
            eprint "${CLRwarn}[WARNING] Option '-$OPTARG' not Valid! -> IGNORED";
            ;;
    esac
done
shift "$((OPTIND-1))"

## If called without argument ${app-name} Exit 0
set -x
AppName="$1"
[ -z "$AppName" ] && the_end "${CLRwarn}[WARNING] Missing argument APP-NAME . Nothing to do ..." 0

## Default Value for "$FpmUser"
FpmUser=${FpmUser:-"$DEFAULT_FPM_USER"}
## Default Value for "$FpmGroup"
FpmGroup=${FpmGroup:-"$FpmUser"}
## Default Value for "$FpmConfDir"
FpmConfDir=${FpmConfDir:-"$DEFAULT_FPM_CONF_DIR"}
## Default Value for "$TemplateName"
TemplateName=${TemplateName:-"$DEFAULT_TEMPLATE_NAME"}
## Set "$TemplatePath"
TemplatePath="${FpmConfDir}/${TemplateName}"
## Set "$DestPath"
DestPath="${FpmConfDir}/${AppName}.conf"
set +x

## Get template
get_template || exit $?

## Create POOL from template
copy_template || exit $?

set -u
sed -ri \
    -e 's!__WWW_USER__!'"$FpmUser"'!g' \
    -e 's!__WWW_GROUP__!'"$FpmGroup"'!g' \
    -e 's!__WWW_APP_NAME__!'"$AppName"'!g' \
    "$DestPath";

# END of script
status=$?
if [ $status -eq 0 ]; then
    eprint "${CLRh1}[END] Executed: $0 :)"
else
    eprint "${CLRerr}[ERROR] got error from SED command :("
fi

exit $((status))

