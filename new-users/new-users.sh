#!/bin/bash
function minecraft-spam {
MINECRAFT_DIR=`cat new-users.conf | grep -w Minecraft-dir: | awk '{printf $2}'`
USER_DB=`cat new-users.conf | grep -w User-file: | awk '{printf $2}'`
USERNAME=`tail -n 1 $MINECRAFT_DIR/server.log | grep -w 'logged in' | awk '{printf $4}' 2> /dev/null`
EXISTING_USER=`cat $USER_DB | grep -w $USERNAME 2> /dev/null`
SCREEN_NAME=`cat new-users.conf | grep -w Screen-name: | awk '{printf $2}'`
if [ "$USERNAME" == "$EXISTING_USER" ]; then
	if [ "$USERNAME" == "" ]; then
		echo "..."
	else
		echo "User exists..."
	fi
elif [ "$USERNAME" == "" ]; then
	echo "..."
else
	echo "User $USERNAME does not exist."
	echo "Spamming user."
	screen -p 0 -S $SCREEN_NAME -X stuff "`printf "tell $USERNAME Welcome to Donclurd Incorporated, $USERNAME!\r"`"
	screen -p 0 -S $SCREEN_NAME -X stuff "`printf "tell $USERNAME Go forth and explore in our lands.\r"`"
	screen -p 0 -S $SCREEN_NAME -X stuff "`printf "tell $USERNAME Never expect a free lunch though.\r"`"
	screen -p 0 -S $SCREEN_NAME -X stuff "`printf "tell $USERNAME You may now leave this island in the shadow of others who once stood in your position.\r"`"
	printf "$USERNAME\n" >> $USER_DB
fi
}
for (( ; ; ))
do
minecraft-spam
sleep 0.1
done
