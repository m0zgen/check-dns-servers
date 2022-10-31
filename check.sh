#!/bin/bash
# Cretaed by Yevgeniy Gonvharov, https://sys-adm.in
# DNS checker - Certificate date, DNS resolve, HTTP 200

# Envs
# ---------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd); cd $SCRIPT_PATH

# Initial variables
# ---------------------------------------------------\

# Telegram settings
TOKEN="<TOKEN>"
CHAT_ID="<ID>"

# Checks arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--resolver) _RESOLVER=1 _RESOLVER_DATA=$2; ;; # Custom resolver IP
        -d|--days) _DAYS=1 _DAYS_DATA=$2; ;;
        -a|--add) _ADD=1 _ADD_DATA=$2; ;; # Add domain to default.txt
        -s|--sort) _SORT=1; ;;
        -l|--list) _LIST=1 _LIST_DATA=$2; shift ;;
        # -h|--help) usage ;; 
        *) _DEFAULT=1 ;;
    esac
    shift
done

# Default Options
if [[ "$_RESOLVER" -eq "1" ]]; then
    CUSTOM_DNS="$_RESOLVER_DATA"
else
    CUSTOM_DNS="1.1.1.1"
fi

if [[ "$_DAYS" -eq "1" ]]; then
    MAX_DAYS="$_DAYS_DATA"
else
    # Domain max days expires
    MAX_DAYS=10
fi

if [[ "$_LIST" -eq "1" ]]; then
    DOMAINs=`cat $_LIST_DATA`
else
    # Domain max days expires
    DOMAINs=`cat $SCRIPT_PATH/domains.txt`
fi



PORTs=`cat $SCRIPT_PATH/ports.txt`

# ---------------------------------------------------\

# And colors
RED='\033[0;91m'
GREEN='\033[0;92m'
CYAN='\033[0;96m'
YELLOW='\033[0;93m'
PURPLE='\033[0;95m'
BLUE='\033[0;94m'
BOLD='\033[1m'
WHiTE="\e[1;37m"
NC='\033[0m'

Info() {
    echo -en "${1}${GREEN}${2}${NC}\n"
}

space() { 
    echo -e ""
}

# Checks supporting distros
checkDistro() {
    # Checking distro
    _DIST_TYPE="$(uname -s)"
    case "${_DIST_TYPE}" in
        Linux*)     _platform_type=Linux;;
        Darwin*)    _platform_type=Mac;;
        CYGWIN*)    _platform_type=Cygwin;;
        MINGW*)     _platform_type=MinGw;;
        *)          _platform_type="UNKNOWN:${_DIST_TYPE}"
    esac
    # echo ${_platform_type}
}

getDate() {
    date '+%Y%m%d'
}

# ---------------------------------------------------\

checkDistro

function getDNSInfo() {
    echo -e "\nChecking from DNS server: ${CUSTOM_DNS}"

    for d in ${DOMAINs}; do

        Info "\n----------------------- Working with domain name: $d -----------------------"
        ips=$(dig @"$CUSTOM_DNS" +short $d)

        for ip in ${ips}; do

            Info "\n----------------------- Starting from IP: $ip -----------------------"

            for p in ${PORTs}; do

                # echo -e "\nChecking domain: ${d}. Port: $ip:$p"
                if [[ "$p" -eq 53 ]]; then

                    echo -e "\nDNS Port detected. Try to resolve Google DNS IP:"
                    response=`nslookup google.com ${ip} | grep -i 'address' | awk 'NR>1' | awk '{print $2}'`
                    if [ -z "$response" ]; then
                        echo "Empty reply from ${ip} :( "
                    else
                        echo -e "${response}"
                    fi

                else

                    echo -e '\x1dclose\x0d' | curl --silent -o /dev/null --connect-timeout 2 telnet://"${ip}":${p} 2>/dev/null
                    if [[ $? -eq 0 ]]; then
                        # openssl s_client -connect ${ip}:8443 -servername ${d} 2>/dev/null | openssl x509 -noout -dates
                        data=`echo "Q" | openssl s_client -connect ${ip}:${p} -servername ${d} 2>/dev/null | openssl x509 -noout -dates`
                        # cn_name=`openssl s_client -connect ${ip}:${p} -servername ${d} 2>/dev/null | grep 'subject=/CN=' | rev | cut -d'=' -f1 | rev`
                        crt_start=`echo "$data" | grep 'notBefore='`
                        crt_end=`echo "$data" | grep 'notAfter='`
                        echo -e "Port: ${p}. Cert info - Start: ${crt_start//notBefore=/} / End: ${crt_end//notAfter=/}"
                        # printf "\rReleased: $crt_start; End: $crt_end"

                        # if Linux
                        if [[ "$1" == "Linux" ]]; then
                            curent_date=$(getDate)
                            expire_date=$(date  -d "${crt_end//notAfter=/}" '+%Y%m%d') 
                            left_days=$((($(date +%s -d ${expire_date})-$(date +%s -d ${curent_date}))/86400))

                            # echo "Current: $curent_date. Expire: $expire_date"

                            if [[ "${left_days}" -lt "${MAX_DAYS}" ]]; then
                                echo -e "[${RED}✓${NC}] Max days: ${PURPLE}${MAX_DAYS}${NC}. Left days: ${RED}${BOLD}${left_days}. Need Update!${NC}"
                            else
                                echo -e "[${GREEN}✓${NC}] Max days: ${YELLOW}${MAX_DAYS}${NC}. Left days: ${GREEN}${BOLD}${left_days}. OK${NC}"
                            fi
                        fi

                    else
                        echo "Port: ${p}. Not available."
                    fi
                fi

                
            done

        done

    done
}

# ---------------------------------------------------\

if [[ "${_platform_type}" == "Linux" ]]; then
    echo -e "\n${GREEN}${BOLD}Linux platform detected...${NC}"
    getDNSInfo "Linux"
elif [[ "${_platform_type}" == "Mac" ]]; then
    echo -e "MacOS platform detected..."
    getDNSInfo "Mac"
else
    getDNSInfo
fi

# openssl s_client -connect xxx.xxx.xx.x:853 -servername ns.server.local