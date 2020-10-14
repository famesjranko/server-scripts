#!/bin/bash

# set grep colour to green
export GREP_COLORS='ms=92'

#####
##### FAIL2BAN
fail2ban () {
	## get fail2ban client names list
	clients=$( sudo fail2ban-client status | grep list | cut -c 15-)

	## clean list of trailing commas ,
	clients_cleaned=${clients//, / }

	## print status of all jails
	echo
	echo "[FAIL2BAN JAIL STATS]"
	echo "================================= START"
	echo
	for value in $clients_cleaned; do
		echo "press any key for next"
		read -n 1
		sudo fail2ban-client status $value #| sed 's/,//g'
		echo
	done
	echo "=================================== END"
	echo
	echo "press any key to return to menu"
	read -n 1
}

#####
##### SYSTEMD
systemd () {
	## list of systemd enabled services
	services=(
	    nginx.service
	    openvpn@server.service
	    fail2ban.service
	    qbittorrent.service
	    containerd.service
	    docker.service
	    webmin.service)

	## print status of systemd services
	echo
	echo "[SYSTEMD SERVICES STATS]"
	echo "================================= START"
	echo
	for service in "${services[@]}"; do
	    echo "press any key for next"
	    read -n 1
	    sudo systemctl status $service | head -n 1 | grep $service --color=auto
	    sudo systemctl status $service | grep "Loaded" --color=auto
	    sudo systemctl status $service | grep "Active" --color=auto
	    echo
	done
	echo "=================================== END"
	echo
	echo "press any key to return to menu"
	read -n 1
}

#####
##### NGINX
nginx () {
	echo "[NGINX WEB-SERVER STATS]"
	echo "================================= START"
	echo
	curl http://127.0.0.1/nginx_status
	echo
	echo "=================================== END"
	echo
	echo "press any key to return to menu"
	read -n 1
}

#####
##### SYSSTATS MENU
sysstats_menu_print () {
clear
cat<<EOF
    =======================================
    Sysstats Menu
    =======================================
    Please enter your choice:

    Option (1) mpstat
    Option (2) pidstat
    Option (3) iostat
    Option (4) display block device stats
        or (B)ack to main menu
    ========================================
EOF
}

#####
##### SYSSTATS
sysstats () {
clear
sysstats_menu_print

while :
do
    read -n1 -s
    case "$REPLY" in
    "1")  clear && mpstat     && echo "press any key to return to menu" && read -n 1 && sysstats_menu_print ;;
    "2")  clear && pidstat    && echo "press any key to return to menu" && read -n 1 && sysstats_menu_print ;;
    "3")  clear && iostat     && echo "press any key to return to menu" && read -n 1 && sysstats_menu_print ;;
    "4")  clear && iostat -p  && echo "press any key to return to menu" && read -n 1 && sysstats_menu_print ;;
    "B")  clear && break                   ;;
    "b")  clear && break                   ;;
     * )  echo "invalid option"            ;;
    esac
done
}


#####
##### MAIN MENU
main_menu_print () {
clear
cat<<EOF
    =======================================
    System Status Menu
    =======================================
    Please enter your choice:

    Option (1) fail2ban ban stats
    Option (2) systemd service stats
    Option (3) nginx web-server stats
    Option (4) sysstats menu
        or (Q)uit
    =======================================
EOF
}

##### MAIN
#####
main () {
clear
main_menu_print

while :
do
    read -n1 -s
    case "$REPLY" in
    "1")  clear && fail2ban && main_menu_print ;;
    "2")  clear && systemd && main_menu_print ;;
    "3")  clear && nginx && main_menu_print ;;
    "4")  clear && sysstats && main_menu_print ;;
    "Q")  clear && exit 0 ;;
    "q")  clear && exit 0 ;;
     * )  echo "invalid option" ;;
    esac
done
}

## execute main
main
echo
