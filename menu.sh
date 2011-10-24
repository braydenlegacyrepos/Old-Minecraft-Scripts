#!/bin/bash
OPTIONS="Op Ban/Kick Misc Whitelist Save Gamemode"
MINECRAFT_DIR=`cat options.txt | grep Minecraft_dir: | awk '{printf $2}'`
SCREEN_NAME=`cat options.txt | grep Screen_name: | awk '{printf $2}'`
#	if [ "$1" != "" ]; then
#		printf "You supplied $1.\n"
#	else
#		printf "Please supply a name as an argument.\n"
#		exit
#	fi
function backup {
	START=$(date +%s)
	TERM=linux
	export TERM
	DIR=`cat options.txt | grep Backup_source: | awk '{printf $2}'`
	BACKUP=`cat options.txt | grep Backup_destination: | awk '{printf $2}'`
	printf "Beginning backup!\n"
	screen -p 0 -S $SCREEN_NAME -X stuff "`printf "say Starting backup!\r"`"
	screen -p 0 -S $SCREEN_NAME -X stuff "`printf "save-all\r"`"
	sleep 1
	screen -p 0 -S $SCREEN_NAME -X stuff "`printf "save-off\r"`"
	rdiff-backup -v0 --print-statistics $DIR $BACKUP
	screen -p 0 -S $SCREEN_NAME -X stuff "`printf "save-on\r"`"
	sleep 1
	screen -p 0 -S $SCREEN_NAME -X stuff "`printf "save-all\r"`"
	screen -p 0 -S $SCREEN_NAME -X stuff "`printf "say Finished backup!\r"`"
	END=$(date +%s)
	DIFF=$(( $END - $START ))
	printf "Finished backup!"
	printf "\nBackup took $DIFF seconds to complete.\n"
	screen -p 0 -S $SCREEN_NAME -X stuff "`printf "say Backup took $DIFF seconds to complete.\r"`"
	exit 0
}
select opt in $OPTIONS; do
	if [ "$opt" = "Op" ]; then
		OP_OPTIONS="Promote Demote"
		select op in $OP_OPTIONS; do
			if [ "$op" = "Promote" ]; then
				printf "Please type in the username to promote.\nName: "
				read username
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "op $username\r"`"
				# Wait for Minecraft to update ops.txt, normally it isn't instant enough to keep up, the delay is barely noticeable. Especially on slowish SSH sessions.
				sleep 0.1
				op_check=`cat $MINECRAFT_DIR/ops.txt | grep -w $username`
					if [ "$username" == "$op_check" ]; then
						printf "$username was promoted to operator successfully and is present in ops.txt\n"
						exit 0
					else
						printf "Attempted to op $username however $username is not present in ops.txt\n"
						exit 0
					fi
			elif [ "$op" = "Demote" ]; then
				printf "Current operators:\n"
				cat $MINECRAFT_DIR/ops.txt
				printf "Please type in the username to demote.\nName: "
				read username
				username_check=`cat $MINECRAFT_DIR/ops.txt | grep -w $username`
					if [ "$username" == "$username_check" ]; then
						screen -p 0 -S $SCREEN_NAME -X stuff "`printf "deop $username\r"`"
						# Wait for Minecraft to update ops.txt, normally it isn't instant enough to keep up, the delay is barely noticeable. Especially on slowish SSH sessions.
						sleep 0.1
						username_check2=`cat $MINECRAFT_DIR/ops.txt | grep -w $username`
							if [ "$username" != "$username_check2" ]; then
								printf "Deop'd $username and found they're not present in ops.txt anymore (this is a good thing).\n"
								exit 0
							else
								printf "Attempted to deop $username however checked ops.txt and discovered the username is still present.\n"
								exit 0
							fi
					else
						printf "Could not find $username in $MINECRAFT_DIR/ops.txt!\n"
						exit 0
					fi
			else
				printf "Please select an option.\n"
			fi
		done
	elif [ "$opt" = "Ban/Kick" ]; then
		KICKBAN_OPT="Kick Ban Ban-IP Unban Unban-IP"
		select kickban in $KICKBAN_OPT; do
			if [ "$kickban" = "Kick" ]; then
				printf "Please type in the username to kick.\nName: "
				read username
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "kick $username\r"`"
				printf "Attempted to kick $username.\n"
				exit
			elif [ "$kickban" = "Ban" ]; then
				printf "Please type in the username to ban.\nName: "
				read username
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "ban $username\r"`"
				sleep 0.1
				ban_check=`cat $MINECRAFT_DIR/banned-players.txt | grep -w $username`
					if [ "$username" == "$ban_check" ]; then
						printf "$username was successfully banned.\n"
						exit 0
					else
						printf "Attempted to ban $username however they were not present in $MINECRAFT_DIR/banned-players.txt\n"
						exit 0
					fi
			elif [ "$kickban" = "Ban-IP" ]; then
				printf "Please insert the IP address as-is, e.g. 117.53.171.171, no CIDR or wildcards.\nIP: "
				read ip
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "ban-ip $ip\r"`"
				# Give some time for Minecraft to write the IP in.
				sleep 0.1
				ip_check=`cat $MINECRAFT_DIR/banned-ips.txt | grep "\<$ip\>"`
					if [ "$ip_check" == "$ip" ]; then
						printf "$ip was banned successfully!\n"
						exit 0
					else
						printf "Attempted to ban $ip however $ip was not present in banned-ips.txt.\n"
						exit 0
					fi
			elif [ "$kickban" = "Unban" ]; then
				printf "Currently banned players:\n"
				cat $MINECRAFT_DIR/banned-players.txt
				printf "Please type the username to unban.\nName:"
				read username
				PLAYER=`cat $MINECRAFT_DIR/banned-players.txt | grep -w $username`
				if [ "$PLAYER" != "" ]; then
					screen -p 0 -S $SCREEN_NAME -X stuff "`printf "pardon $username\r"`"
					printf "Unbanned $username.\n"
					exit 0
				else
					printf "The player $username was not found in banned-players.txt. Please specify the username exactly as-is and try again.\n"
					exit
				fi
			elif [ "$kickban" = "Unban-IP" ]; then
				printf "Please insert the IP address as-is, e.g. 117.53.171.171, no CIDR or wildcards.\n"
				printf "Currently banned:\n"
				cat $MINECRAFT_DIR/banned-ips.txt
				printf "IP: "
				read ip
				address=`cat $MINECRAFT_DIR/banned-ips.txt | grep "\<$ip\>"`
					if [ "$address" == "$ip" ]; then
						screen -p 0 -S $SCREEN_NAME -X stuff "`printf "pardon-ip $ip\r"`"
						printf "Removed $ip from banned-ips.txt\n"
						exit 0
					else
						printf "Please specify an IP address that is actually in banned-ips.txt next time.\n"
						exit 0
					fi
			else
				printf "Please select an option.\n"
			fi
		done
	elif [ "$opt" = "Misc" ]; then
		MISC_OPTIONS="Say Stop Teleport Time Backup"
		select misc in $MISC_OPTIONS; do
			if [ "$misc" = "Say" ]; then
				printf "Please type what you want to say.\nSay: "
				read SAY
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "say $SAY\r"`"
				printf "Said '$SAY' to the server.\n"
				exit
			elif [ "$misc" = "Stop" ]; then
				printf "Do you want to stop the server? Y or N.\n"
				read yn
				case $yn in
					[Yy]* ) screen -p 0 -S $SCREEN_NAME -X stuff "`printf "stop\r"`";;
					[Nn]* ) exit $?;;
				esac
			elif [ "$misc" = "Teleport" ]; then
				printf "Enter the first username, the first username will be teleported to the second username.\nName: "
				read name1
				printf "Now enter the second username, the first username will be teleported to the second username.\nName: "
				read name2
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "tp $name1 $name2\r"`"
				printf "$name1 should now have been teleported to $name2.\n"
				exit
			elif [ "$misc" = "Time" ]; then
				TIME_OPTIONS="Dawn Midday Dusk Midnight"
				select time in $TIME_OPTIONS; do
					if [ "$time" = "Dawn" ]; then
                                		screen -p 0 -S $SCREE_NAME -X stuff "`printf "time set 0\r"`"
                                		printf "Set time to $time\n"
                                		exit
                        		elif [ "$time" = "Midday" ]; then
                                		screen -p 0 -S $SCREEN_NAME -X stuff "`printf "time set 6000\r"`"
                                		printf "Set time to $time\n"
                                		exit
                        		elif [ "$time" = "Dusk" ]; then
                                		screen -p 0 -S $SCREEN_NAME -X stuff "`printf "time set 12000\r"`"
                                		prinf "Set time to $time\n"
                                		exit
                        		elif [ "$time" = "Midnight" ]; then
                                		screen -p 0 -S $SCREEN_NAME -X stuff "`printf "time set 18000\r"`"
                                		printf "Set time to $time\n"
                                		exit
                       			else
                                		printf "Please select a time.\n"
                        		fi
				done
			elif [ "$misc" = "Backup" ]; then
				backup
				exit 0
			else
				printf "Please select an option\n"
			fi
		done
	elif [ "$opt" = "Time" ]; then
                DAY_NIGHT="Dawn Midday Dusk Midnight"
                select time in $DAY_NIGHT; do
                        if [ "$time" = "Dawn" ]; then
                                screen -p 0 -S $SCREEN_NAME -X stuff "`printf "time set 0\r"`"
                                printf "Set time to $time\n"
                                exit
                        elif [ "$time" = "Midday" ]; then
                                screen -p 0 -S $SCREEN_NAME -X stuff "`printf "time set 6000\r"`"
                                printf "Set time to $time\n"
                                exit
                        elif [ "$time" = "Dusk" ]; then
                                scren -p 0 -S $SCREEN_NAME -X stuff "`printf "time set 12000\r"`"
                                prinf "Set time to $time\n"
                                exit
                        elif [ "$time" = "Midnight" ]; then
                                screen -p 0 -S $SCREEN_NAME -X stuff "`printf "time set 18000\r"`"
                                printf "Set time to $time\n"
                                exit
                        else
                                printf "Please select a time.\n"
                        fi
                done
	elif [ "$opt" = "Whitelist" ]; then
		whitelist_opt="On Off Add Remove Reload"
		select whitelist in $whitelist_opt; do
			if [ "$whitelist" = "On" ]; then
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "whitelist on\r"`"
				printf "Enabled Whitelist.\n"
				exit
			elif [ "$whitelist" = "Off" ]; then
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "whitelist off\r"`"
				printf "Disabled Whitelist.\n"
				exit
			elif [ "$whitelist" = "Add" ]; then
				printf "Enter the username to be added to the whitelist.\nName: "
				read username
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "whitelist add $username\r"`"
				printf "Added $username to the whitelist.\n"
				exit
			elif [ "$whitelist" = "Remove" ]; then
				printf "Currently whitelisted users:\n"
				cat $MINECRAFT_DIR/white-list.txt
				printf "Enter the username to be removed from the whitelisted:\nName: "
				read username
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "whitelist remove $username\r"`"
				sleep 0.1
				username_check=`cat $MINECRAFT_DIR/white-list.txt | grep -w $username`
					if [ "$username_check" == "$username" ]; then
						printf "Attempted to remove $username however they're still present in white-list.txt\n"
						exit 0
					else
						printf "Successfully removed $username from the whitelist.\n"
						exit 0
					fi
			elif [ "$whitelist" = "Reload" ]; then
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "whitelist reload\r"`"
				printf "Reloaded the whitelist.\n"
				exit
			else
				printf "Please select an option.\n"
			fi
		done
	elif [ "$opt" = "Save" ]; then
		SAVE_OPT="On Off All"
		select save in $SAVE_OPT; do
			if [ "$save" = "On" ]; then
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "save-on\r"`"
				printf "Enabled level saving.\n"
				exit
			elif [ "$save" = "Off" ]; then
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "save-off\r"`"
				printf "Enabling level saving.\n"
				exit
			elif [ "$save" = "All" ]; then
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "save-all\r"`"
				printf "Saved the map, allow a second or two as this can be a bit slow on large worlds.\n"
				exit
			else
				printf "Please select an option.\n"
			fi
		done
	elif [ "$opt" = "Gamemode" ]; then
		GAMEMODE_OPT="Survival Creative"
		select gamemode in $GAMEMODE_OPT; do
			if [ "$gamemode" = "Survival" ]; then
				printf "Enter the username to enable Survival on.\nName: "
				read username
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "gamemode $username 0\r"`"
				printf "Enabled Survival for $username.\n"
				exit
			elif [ "$gamemode" = "Creative" ]; then
				printf "Enter the username to enable Creative on.\nName: "
				read username
				screen -p 0 -S $SCREEN_NAME -X stuff "`printf "gamemode $username 1\r"`"
				printf "Enabled Creative for $username.\n"
				exit
			else
				printf "Please select an option.\n"
			fi
		done
	else
		printf "Please select an option.\n"
	fi
done
