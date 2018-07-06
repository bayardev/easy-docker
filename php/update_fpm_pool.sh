#!/bin/sh
# shellcheck disable=SC2034,SC2154

set -a
# Constants
readonly DEFAULT_FPM_CONF_DIR="/usr/local/etc/php-fpm.d"
readonly DEFAULT_FPM_POOL="www"
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

update_line_if()
{
    if [ -n "$1" ]; then
        if grep "^\\;\\?\\s*\\?${1} =.*" "${PoolConfPath}" > /dev/null; then
            if [ "$2" = ";" ]; then
                sed -i "s#^\\;\\?\\s*\\?${1} =.*\\?#\\;${1} = #" "${PoolConfPath}" \
                    && eprint "[INFO] Commented: ';$1 = ' in ${PoolConfPath}";
            else
                sed -i "s#^\\;\\?\\s*\\?${1} =.*\\?#${1} = ${2}#" "${PoolConfPath}" \
                    && eprint "[INFO] Applied: '$1 = $2' in ${PoolConfPath}";
            fi
        else
            eprint "[WARNING] Conf Key $1 NOT FOUND in ${PoolConfPath}";
        fi
    fi
}

usage()
{
    eprint "${CLRh2}[Synopsis]"
    eprint "    Modify a fpm-pool.conf values if specific env-vars are setted"
    eprint "${CLRh2}[Usage]"
    eprint "    $0 [-options] [pool-name]"
    eprint "${CLRh2}[Options]"
    eprint "    -h  print this help and exit"
    eprint "    -d <fpm-conf-dir>  php-fpm conf dir ${CLRspan}(default: '${DEFAULT_FPM_CONF_DIR}')"
    eprint "${CLRh2}[Examples]"
    eprint "       $0 myapp"
    eprint "       FPM_USER='myuser' $0"
    eprint "       FPM_LISTEN_MODE='0666' $0 -d /etc/php-fpm.d"

    ExitStatus=${1:-"0"}
    exit $((ExitStatus))
}

## OPTIONS
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts ":hd:" opt; do
    case "$opt" in
        h) # Print usage() & exit
            usage 0;
            ;;
        d) # Set FpmConfDir
            FpmConfDir="$OPTARG"
            ;;
        :) # If Option require an argument and none given, Exit with Error
            eprint "[ERROR] Option '-$OPTARG' require a value"; usage 40;
            ;;
        ? | *) # If not valid Option : print Warning
            eprint "[WARNING] Option '-$OPTARG' not Valid! -> IGNORED";
            ;;
    esac
done
shift "$((OPTIND-1))"

# Print START script execution
eprint "[START]: $0"

FoundEnvVars=$(env | grep -E '^FPM_\w*=')
eprint "[INFO] Found EnvVars: \\n${FoundEnvVars}"

## Default Value for "$PoolName"
PoolName=${1:-"$DEFAULT_FPM_POOL"}
## Default Value for "$FpmConfDir"
FpmConfDir=${FpmConfDir:-"$DEFAULT_FPM_CONF_DIR"}
## Set value for "$PoolConfPath"
PoolConfPath="${FpmConfDir}/${PoolName}.conf"
export PoolConfPath

## If <app-name>.conf file not found exit with error
if [ ! -f "$PoolConfPath" ]; then
    eprint "[ERROR] ${PoolConfPath} NOT FOUND! Please verify app-name and fpm-conf-dir ..."; the_end 44;
fi

IniSetList=$(echo "$FoundEnvVars" | awk -F "=" \
'{
    ini_key = gensub(/_/, ".", 1, substr(tolower($1), 5))
    ini_value = gensub(/'\''/, "", "g", $2)

    print ini_key "=" ini_value;
}')

for IniSet in $IniSetList; do
    # shellcheck disable=SC2046
    update_line_if $(printf '%s' "$IniSet" | tr '=' ' ')
done

# Exit Success
the_end;
