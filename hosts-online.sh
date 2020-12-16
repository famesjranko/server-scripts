#!/bin/bash


## ====================================
## SET NETWORK INFORMATION
## ====================================

# set network info
networks=2

lan1_name=landofoz-1
lan1_ip=192.168.20.0/24

lan2_name=landofoz-2
lan2_ip=192.168.10.0/24

# list of allowed network host address
declare -a lan1_allowed=(
"192.168.20.1
192.168.20.2
192.168.20.3
192.168.20.4
192.168.20.5
192.168.20.6
192.168.20.8
192.168.20.9
192.168.20.10
192.168.20.11
192.168.20.90
192.168.20.91
192.168.20.92
192.168.20.200
192.168.20.203
192.168.20.204")

declare -a lan2_allowed=(
"192.168.10.1
192.168.10.2")


## ====================================
## COLLECT NETOWKR DATA
## ====================================

# modify network address for search
modify() {
    echo $1 | cut -c -11
}

lan1_mod=$(modify $lan1_ip)
lan2_mod=$(modify $lan2_ip)

## get corresponding network host search
network_search() {
    nmap -sn -PS $1 | grep "$2" | sed 's/.* //'
}

hosts_lan1=$(network_search $lan1_ip $lan1_mod)
hosts_lan2=$(network_search $lan2_ip $lan2_mod)

## get number of hosts on networks
host_count() {
    local  count=( $@ )
    echo "$count"
}

hostsOn_lan1=( $hosts_lan1 )
hostsOn_lan2=( $hosts_lan2 )


## ====================================
## SORT NETWORK DATA
## ====================================

sort_hosts() {
    #echo "this is list for loop in function: $1"
    local sorted=$(for h in "$@"
                   do
                       #echo "in loop:"
                       ip=$(echo "$h" | tr -d '()')
                       echo $ip
                  done | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4)
    echo $sorted
}

lan1_sorted=$(sort_hosts $hosts_lan1 )
lan2_sorted=$(sort_hosts $hosts_lan2 )


## ====================================
## DISPLAY DATA
## ====================================

## display active network hosts lan1
printf "CURRENT ACTIVE HOSTS ON LOCAL NETWORKS: \n\n"

output() {
    local lan_name=$1
    local lan_ip=$2# ASCI colours for output
    local hosts_on=$3
    local sorted_hosts=$4
    local allowed_hosts=$5

    # ASCI colours for output
    local GREEN='\033[1;32m'
    local RED='\033[1;31m'
    local RESET='\033[0m'

    printf "$lan_name \n($lan_ip) \n"
    echo "hosts online: $3"

    local i=1
    local match=0
    for ip in $sorted_hosts
    do
        for a in ${allowed_hosts[@]}
        do
            if [ "$a" == "$ip" ]; then
                printf "\t$i: $ip \t( ${GREEN}ALLOWED${RESET} )\n"
                match=1
                break
            fi
        done

        if [ $match == 0 ]; then
             printf "\t$i: $ip \t( ${RED}UNKNOWN${RESET} ) <- \n"
        fi

        match=0
        ((i++))
    done
}

output $lan1_name $lan1_ip $hostsOn_lan1 "$lan1_sorted" "$lan1_allowed"
output $lan2_name $lan2_ip $hostsOn_lan2 "$lan2_sorted" "$lan2_allowed"


exit
