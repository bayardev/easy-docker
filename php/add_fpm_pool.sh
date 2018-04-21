#!/bin/sh
set -ea

## Default Values (CONSTANTS)
readonly DEFAULT_FPM_USER="www-data"
readonly DEFAULT_FPM_CONF_DIR="/usr/local/etc/php-fpm.d"
readonly DEFAULT_TEMPLATE_NAME="pool.conf.tpl"
readonly GET_TEMPLATE_FROM="https://raw.githubusercontent.com/bayardev/easy-docker/master/php/etc"

## COLORS
CLR0='\e[0m'
CLRh1='\e[1;32m'
CLRh2='\e[32m'
CLRspan='\e[33m'
CLRwarn='\e[1;33m'
CLRerr='\e[41;1;37m'
CLRinfo='\e[32m'
CLRnotice='\e[1;36m'

eprint()
{
    msg="${*}"
    printf '%b%b\n' "$msg" "$CLR0"
}

the_end()
{
    msg="$1"
    exit_status=${2:-"0"}

    eprint "$msg"
    [ -z "$3" ] && eprint "> ${CLRinfo}Use: $0 -h for help";
    exit $((exit_status))
}

get_template()
{
    status=0
    if [ ! -f "$TemplatePath" ]; then
        if result=$(curl -sSfLk -o "${TemplatePath}" "${GET_TEMPLATE_FROM}/${TemplateName}" 2>&1); then
            eprint "${CLRinfo}[INFO] ${TemplateName} imported in ${TemplatePath}"
        else
            status=$?
            eprint "${CLRerr}Failed to get ${GET_TEMPLATE_FROM}/${TemplateName}";
            eprint "${CLRerr}[ERROR] ${result}";
        fi
    else
        eprint "${CLRnotice}[NOTICE] Template ${TemplatePath} Already exists. Will not be imported again..."
    fi

    return $((status))
}

copy_template()
{
    status=0
    cp_cmd='cp'
    [ -n "$Force" ] && cp_cmd='cp -f'

    if result=$(${cp_cmd} "$TemplatePath" "$DestPath" 2>&1); then
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
    eprint "   $0 [-options] <app-name> [user] [group]"
    eprint "${CLRh2}[Options]"
    eprint "    -h  print this help and exit"
    eprint "    -d <fpm-conf-dir>  php-fpm conf dir ${CLRspan}(default: '${DEFAULT_FPM_CONF_DIR}')"
    eprint "    -t <template-name>  pool template-name ${CLRspan}(default: '${DEFAULT_TEMPLATE_NAME}')"
    eprint "${CLRh2}[Examples]"
    eprint "       $0 myapp myuser"
    eprint "       $0 -d /etc/php-fpm.d myapp php-fpm"
    eprint "${CLRh2}[Defaults]"
    eprint "    user  : ${DEFAULT_FPM_USER}"
    eprint "    group : If the group is not set, the default user's group will be used"


    exit_status=${1:-"0"}
    exit $((exit_status))
}

# Print START script execution
eprint "${CLRh1}[START]: $0"

## OPTIONS
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts ":hfd:t:" opt; do
    case "$opt" in
        h) # Print usage() & exit
            usage 0;
            ;;
        f) # Set Force
            Force="-f";
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

## If called without argument <app-name> Exit 0
AppName="$1"
[ -z "$AppName" ] && the_end "${CLRwarn}[WARNING] Missing argument APP-NAME. Nothing to do ..." 0

## Default Value for "$FpmUser"
FpmUser=${2:-"$DEFAULT_FPM_USER"}
## Default Value for "$FpmGroup"
FpmGroup=${3:-"$FpmUser"}

## Default Value for "$FpmConfDir"
FpmConfDir=${FpmConfDir:-"$DEFAULT_FPM_CONF_DIR"}
## Default Value for "$TemplateName"
TemplateName=${TemplateName:-"$DEFAULT_TEMPLATE_NAME"}
## Set "$TemplatePath"
TemplatePath="${FpmConfDir}/${TemplateName}"
## Set "$DestPath"
DestPath="${FpmConfDir}/${AppName}.conf"

if [ -f "$DestPath" ]; then
    [ -z "$Force" ] && the_end "${CLRwarn}[WARNING] ${DestPath} already exists. Use -f (force) to overwrite. Nothing to do ..." 0
    eprint "${CLRnotice}[NOTICE] Pool ${DestPath} already exists. Got option -f (force): ${DestPath} will be overwritten"
fi

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

