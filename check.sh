#!/bin/bash
# Cretaed by Yevgeniy Gonvharov, https://sys-adm.in
# DNS checker - Certificate date, DNS resolve, HTTP 200

# Envs
# ---------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)

# Initial variables
# ---------------------------------------------------\

# Telegram settings
TOKEN="<TOKEN>"
CHAT_ID="<ID>"

# Domain list
DOMAINs=`cat $SCRIPT_PATH/domains.txt`
PORTs=`cat $SCRIPT_PATH/ports.txt`
CUSTOM_DNS="1.1.1.1"

# ---------------------------------------------------\

Info() {
    echo -en "${1}${green}${2}${nc}\n"
}

space() { 
    echo -e ""
}

# ---------------------------------------------------\

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
                else
                    echo "Port: ${p}. Not available."
                fi
            fi

            
        done

    done

done

# openssl s_client -connect 212.19.134.52:853 -servername bld.sys-adm.in