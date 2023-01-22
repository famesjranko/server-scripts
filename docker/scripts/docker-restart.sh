#!/bin/bash

## ===========================================
## simple stop/restart docker container script
## ===========================================

echo "currently running docker containers: "
docker ps | awk '{ print $2}' | cut -c 13-

echo
printf "stopping containers"

# stop running containers
#docker stop $(docker ps -a -q) > /dev/null 2>&1 &
#docker stop $(docker ps -a -q) &

for (( i=1; i<=3; i++ ))
do
	sleep .2
	printf ". "
done

echo
docker stop $(docker ps -a -q)

echo
printf "wait 5 seconds: "

for (( i=1; i<=5; i++ ))
do
	sleep 1
	#echo "$i"
	printf " $i"
done
sleep 1

echo && echo
printf "restarting containers"

# restart previously stopped containers
#docker start $(docker ps -a -q -f status=exited) > /dev/null 2>&1 &
#docker start $(docker ps -a -q -f status=exited) &

for (( i=1; i<=3; i++ ))
do
        sleep .2
        printf ". "
done
echo
docker start $(docker ps -a -q -f status=exited)

echo
echo "finished!"

exit 0
