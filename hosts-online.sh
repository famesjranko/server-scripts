#!/bin/bash

## =========================================================================
## local network host discovery script that scans for active hosts  on set
## networks and and compares them to a predefined 'allowed' list for matches.
##
## reguires nmap and sudo permission. to use simply set network information 
## in network set section.  to scan more than one network, simply uncomment 
## 'lan2' lines and diplicate for more networks.
## =========================================================================

## ====================================
## SET NETWORK INFORMATION
## ====================================

# set network info: name and CIDR (eg: 192.168.1.0/24)
lan1_name=
lan1_ip=
#lan2_name=
#lan2_ip=

# list of allowed network host ip addresses:
# put IPs between "" seperated by a space (eg: "192.168.1.1 192.168.1.2"
declare -a lan1_allowed=("")
#declare -a lan2_allowed=("")


## ====================================
## COLLECT NETOWKR DATA
## ====================================

# modify network address for search
modify() {
    echo $1 | cut -c -11
}

lan1_mod=$(modify $lan1_ip)
#lan2_mod=$(modify $lan2_ip)

## get corresponding network host search
network_search() {
    nmap -sn -PS $1 | grep "$2" | sed 's/.* //'
}

hosts_lan1=$(network_search $lan1_ip $lan1_mod)
#hosts_lan2=$(network_search $lan2_ip $lan2_mod)

## get number of hosts on networks
host_count() {
    local  count=( $@ )
    echo "$count"
}

hostsOn_lan1=( $hosts_lan1 )
#hostsOn_lan2=( $hosts_lan2 )


## ====================================
## SORT NETWORK DATA
## ====================================

sort_hosts() {
    local sorted=$(for h in "$@"
                   do
                       ip=$(echo "$h" | tr -d '()')
                       echo $ip
                  done | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4)
    echo $sorted
}

lan1_sorted=$(sort_hosts $hosts_lan1 )
#lan2_sorted=$(sort_hosts $hosts_lan2 )


## ====================================
## DISPLAY DATA
## ====================================

## display active network hosts lan1
printf "CURRENT ACTIVE HOSTS ON LOCAL NETWORKS: \n\n"

output() {
    # set local variables
    local lan_name=$1
    local lan_ip=$2
    local hosts_on=$3
    local sorted_hosts=$4
    local allowed_hosts=$5

    # ASCI colours for output
    local GREEN='\033[1;32m'\
    local RED='\033[1;31m'
    local RESET='\033[0m'

    # set counter and check variables
    local count=1
    local match=0

    # print network info
    printf "$lan_name \n($lan_ip) \n"
    echo "hosts online: $3"

    # print active hosts and status
    for ip in $sorted_hosts
    do
        for a in ${allowed_hosts[@]}
        do
            if [ "$a" == "$ip" ]; then
                printf "\t$count: $ip \t( ${GREEN}ALLOWED${RESET} )\n"
                match=1
                break
            fi
        done

        if [ $match == 0 ]; then
             printf "\t$count: $ip \t( ${RED}UNKNOWN${RESET} ) <- \n"
        fi

        # reset match and increment count
        match=0
        ((i++))
    done
}

output $lan1_name $lan1_ip $hostsOn_lan1 "$lan1_sorted" "$lan1_allowed"
#output $lan2_name $lan2_ip $hostsOn_lan2 "$lan2_sorted" "$lan2_allowed"

exit
