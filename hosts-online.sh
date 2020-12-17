#!/bin/bash
## ==========================================================================
## local network host discovery script that scans for active hosts on set
## networks and compares them to a predefined 'allowed' list for matches.
##
## reguires nmap and sudo permission - sudo needed for UDP Ping (-PU) because 
## nmap needs to read raw responses from the network interface
## 
## to use simply set network information in network set section.  to scan more 
## than one network, simply uncomment relevant 'template' lines and follow 
## numbering convention for variables and nmap conditional check.
##
## code structure:  1. [ NETWORK SETTINGS ]
##                  2. [ MAIN FUNCTIONS   ]
##                  3. [ MAIN COMMANDS    ]
##
## set network information in -> [ NETWORK SETTINGS ] sections
##
## NOTE: when adding/removing networks networks follow variable templates 
## structure as shown in [ NETWORK SETTINGS ] and [ MAIN COMMANDS ] sections
## ==========================================================================

## ====================================
## 1. NETWORK SETTINGS
## ====================================

## set network info: name and CIDR (eg: 192.168.1.0/24) and known/allowed ip list - (EG SHOWN)
# --- lan1
lan1_name="EXAMPLE-LAN1"
lan1_ip="192.168.1.0/24"

# set known/allowed ip list as associative array: [key]=value ([ipaddress]=hostname) 
declare -A lan1_knownHosts=( [192.168.1.1]=ROUTER-LAN1 [192.168.1.2]=HOST1 [192.168.1.3]=HOST2 [192.168.1.4]=HOST4)

# --- lan2
#lan2_name="EXAMPLE-LAN2"
#lan2_ip="192.168.2.0/24"

# set known/allowed ip list as associative array: [key]=value ([ipaddress]=hostname)
#declare -A lan2_knownHosts=( [192.168.2.1]=ROUTER.LAN2 [192.168.2.2]=HOST5 )

# --- lan# (template)
#lan#_name=""      # (template#)
#lan#_ip=""        # (template#)
#declare -A lan#_allowed=([IP-ADDRESS]=NAME) # (template#)

## ====================================
## 1. MAIN FUNCTIONS
## ====================================

## modifies network address for search
modify() {
  echo $1 | cut -c -11
}

## runs nmap network host search
network_search() {
  nmap -sn -PS -PR -PA -PU $1 | grep "$2" | sed 's/.* //'
}

## returns addresses sorted in ascending order
sort_hosts() {
  local sorted=$(for h in "$@"; do
                   ip=$(echo "$h" | tr -d '()')
                   echo $ip;
                 done | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4)
  echo $sorted
}

## displays retrieved network info
output() {
  # set local variables
  local lan_name=$1
  local lan_ip=$2
  local sorted_hosts=$3
  local -n allowed_hosts=$4

  # ASCI colours and style for output
  local ALLOWED=$(printf "\033[1;32mALLOWED\033[0m")
  local UNKNOWN=$(printf "\033[1;31mUNKNOWN\033[0m")
  local printStyle1="%5s %-20s %11s\n"
  local printStyle2="%38s\n"

  # set counter and match variable
  local count=1
  local match=0

  # print network name and address
  printf "\n$lan_name \n($lan_ip) \n"

  # print active hosts and status: host is either known/allowed or unknown
  for ip in $sorted_hosts; do
    for a in "${!allowed_hosts[@]}"; do
      if [ "$a" == "$ip" ]; then
        printf "${printStyle1}" "$count:" "${allowed_hosts[$a]}" "( $ALLOWED )"
        match=1
        break
      fi
    done

    if [ $match == 0 ]; then
      printf "${printStyle1}" "$count:" "$ip" "( $UNKNOWN )"
    fi

    match=0
    ((count++))
  done
  printf "${printStyle2}" "-----------------------------------"
  printf "${printStyle2}" "total hosts: $(( $count - 1 ))"
}

## ====================================
## 3. MAIN COMMANDS
## ====================================

## modify network address for search
lan1_mod=$(modify $lan1_ip)
#lan2_mod=$(modify $lan2_ip)
#lan#_mod=$(modify $lan#_ip) # (template#)

## run map network search
lan1_hosts=$(network_search $lan1_ip $lan1_mod)
#lan2_hosts=$(network_search $lan2_ip $lan2_mod)
#lan#_hosts=$(network_search $lan#_ip $lan#_mod) # (template#)

## exit if nmap returns nothing - two networks
## for two networks: if [[ -z "$lan1_hosts" ]] || [[ -z "$lan2_hosts" ]]; then ...
## for extra networks follow conditional structure, eg: ... || [[ -z "$lan#_hosts" ]]; then ...
if [[ -z "$lan1_hosts" ]]; then
  exit 1
fi

## sort network address in ascending order
lan1_hostsSorted=$(sort_hosts $lan1_hosts )
#lan2_hostsSorted=$(sort_hosts $lan2_hosts )
#lan#_hostsSorted=$(sort_hosts $lan#_hosts ) # (template#)

## display network info to terminal
printf "CURRENT ACTIVE HOSTS ON LOCAL NETWORK: \n"
output $lan1_name $lan1_ip "$lan1_hostsSorted" lan1_knownHosts
#output $lan2_name $lan2_ip "$lan2_hostsSorted" lan2_knownHosts
#output $lan#_name $lan#_ip $lan#_hostsOn "$lan#_hostsSorted" "$lan#_knownHosts" # (template#)

exit
