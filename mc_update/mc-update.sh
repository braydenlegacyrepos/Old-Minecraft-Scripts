#!/bin/bash
MC_DIR=`cat mc-update.conf | grep -w 'Minecraft_dir:' | awk '{printf $2}'`
SCREEN_NAME=`cat mc-update.conf | grep -w 'Screen_name:' | awk '{printf $2}'`
function do_update {
if [ "$update_opt" = "WorldGuard" ]; then
	printf "Making temporary directory.\n"
	mkdir ${update_opt}_tmp/
	printf "Downloading ${update_opt}.\n"
	URL=`lynx -dump http://irc.donclurd.com/${update_opt}.txt`
	wget --output-document=${update_opt}_tmp/${update_opt}.zip $URL
	printf "Unpacking ${update_opt} to the temporary folder.\n"
	unzip ${update_opt}_tmp/${update_opt}.zip -d ${update_opt}_tmp/ > /dev/null
	printf "Copying ${update_opt}.jar into the server's plugins directory.\n"
	cp ${update_opt}_tmp/*.jar $MC_DIR/plugins/
	rm $MC_DIR/plugins/worldguard*
	printf "Cleaning up the temporary directory.\n"
	rm -r ${update_opt}_tmp/
elif [ "$update_opt" = "WorldEdit" ]; then
	printf "Making temporary directory.\n"
	mkdir ${update_opt}_tmp/
	printf "Downloading ${update_opt}.\n"
	URL=`lynx -dump http://irc.donclurd.com/${update_opt}.txt`
	wget --output-document=${update_opt}_tmp/${update_opt}.zip $URL
	printf "Unpacking ${update_opt} to the temporary folder.\n"
	unzip ${update_opt}_tmp/${update_opt}.zip -d ${update_opt}_tmp/ > /dev/null
	printf "Copying ${update_opt}.jar into the server's plugins directory.\n"
	cp ${update_opt}_tmp/*.jar $MC_DIR/plugins/
	rm $MC_DIR/plugins/worldedit*
	printf "Cleaning up the temporary directory.\n"
	rm -r ${update_opt}_tmp/
	printf "${update_opt} also has this thing called craftscripts, they're cool things that can automate certain tasks such as creation of pixel art and roofs.\n"
	printf "Do you want the latest craftscripts to be installed? Y or N\nPrompt:"
	read CRAFTSCRIPT_ANSWER
	if [ "$CRAFTSCRIPT_ANSWER" = "Y" ] || [ "$CRAFTSCRIPT_ANSWER" = "y" ]; then
		cp -r ${update_opt}_tmp/craftscripts/ $MC_DIR/
		printf "Attempted to copy the craftscripts in.\n"
	elif [ "$CRAFTSCRIPT_ANSWER" = "N" ] || [ "$CRAFTSCRIPT_ANSWER" = "n" ]; then
		printf "You opted not to copy the craftscripts in.\n"
	else
		printf "You inputted something else. Assuming 'no'.\n"
	fi
	printf "Cleaning up the temporary directory.\n"
	rm -r ${update_opt}_tmp/
elif [ "$update_opt" = "Essentials" ]; then
	printf "Making temporary directory.\n"
	mkdir ~/${update_opt}_tmp/
	printf "Downloading ${update_opt}.\n"
	wget --output-document=~/${update_opt}_tmp/${update_opt}.zip http://tiny.cc/EssentialsZipDownload
	printf "Unpacking ${update_opt} to the temporary folder.\n"
	unzip ~/${update_opt}_tmp/${update_opt}.zip > /dev/null
	printf "Copying ${update_opt}.jar and the rest into the server's plugins directory.\n"
	cp ~/${update_opt}_tmp/*.jar $MC_DIR/plugins/
	printf "Cleaning up the temporary directory.\n"
	rm -r ~/${update_opt}_tmp/
else
	printf "Somehow update_opt was not set to anything useful but you got this far.\n"
	exit 1
fi
}
MENU_OPTIONS="Update Remove Check"
select opt in $MENU_OPTIONS; do
	if [ "$opt" = "Update" ]; then
		UPDATE_OPTIONS="WorldGuard WorldEdit Essentials"
		select update_opt in $UPDATE_OPTIONS; do
			if [ "$update_opt" = "WorldGuard" ]; then
				WEBSITE_VERSION=`lynx -dump http://irc.donclurd.com/${update_opt}.txt`
				LOG_LINES=`cat $MC_DIR/server.log | grep 'WorldGuard' | grep 'enabled.' | wc -l`
				SERVER_VERSION=`cat $MC_DIR/server.log | grep 'WorldGuard' | grep 'enabled.' | sed -n ${LOG_LINES}p | awk '{printf $5}'`
					if [ "$SERVER_VERSION" = "$WEBSITE_VERSION" ]; then
						printf "It appears your $update_opt version, $SERVER_VERSION, is up to date with the response from the website, $WEBSITE_VERSION.\n"
					elif [ "$SERVER_VERSION" != "$WEBSITE_VERSION" ]; then
						printf "Your version is out of date, latest version $WEBSITE_VERSION and your version $SERVER_VERSION.\n"
						printf "If anything but two version numbers came out (e.g. asdf instead of 4.7) then interrupt the script via CTRL+C and attempt again.\n"
						sleep 3
						do_update
						printf "The script will now attempt to intelligently determine the links to download. The way the links are formatted is such that they change from version to version.\n"
						printf "This ensures the script works when a new version comes out. (As it should!)\n"
						printf "Do you want to reload the server to attempt to upgrade now? Please answer Y or N.\nReload:"
						read ANSWER
						if [ "$ANSWER" = "Y" ] || [ "$ANSWER" = "y" ]; then
							screen -p 0 -S $SCREEN_NAME -X stuff "`printf "reload\r"`"
							printf "Attempted to reload the server, check the console to see how that worked out.\n"
						elif [ "$ANSWER" = "N" ] || [ "$ANSWER" = "n" ]; then
							printf "You opted not to reload.\n"
						else
							printf "The script did not understand what you wrote.\n"
							printf "But we will assume you meant no.\n"
						fi
					else
						printf "Something really weird happened. The script will proceed to dump some information to help debug.\n"
						printf "The server version that was read was: $SERVER_VERSION\n"
						printf "The version number that was obtained from the website was: $WEBSITE_VERSION\n"
						printf "Please submit this bug on my Github page, including the information dump, or simply try the script again.\n"
						exit 0
					fi
			elif [ "$update_opt" = "WorldEdit" ]; then
				WEBSITE_VERSION=`lynx -dump http://irc.donclurd.com/${update_opt}.txt`
				LOG_LINES=`cat $MC_DIR/server.log | grep 'WorldEdit' | grep 'enabled.' | wc -l`
				SERVER_VERSION=`cat $MC_DIR/server.log | grep 'WorldEdit' | grep 'enabled.' | sed -n ${LOG_LINES}p | awk '{printf $5}'`
					if [ "$SERVER_VERSION" = "$WEBSITE_VERSION" ]; then
						printf "It appears your WorldEdit version, $SERVER_VERSION, is up to date with the latest version, $WEBSITE_VERSION.\n"
					elif [ "$SERVER_VERSION" != "$WEBSITE_VERSION" ]; then
						printf "It seems your WorldEdit installation is out of date. Current: $SERVER_VERSION New: $WEBSITE_VERSION\n"
						printf "If anything but two version numbers came out (e.g. asdf instead of 4.7) then interrupt the script via CTRL+C and attempt again.\n"
						sleep 0.5
						printf "The script will now attempt to 'intelligently' determine the links to download. The way the links are formatted is such that they change from version to version.\n"
						printf "This ensures the script works when a new version comes out. (As it should!)\n"
						do_update
						printf "Do you want to reload the server to attempt to upgrade now? Please answer Y or N.\nReload:"
						read ANSWER
						if [ "$ANSWER" = "Y" ] || [ "$ANSWER" = "y" ]; then
							screen -p 0 -S $SCREEN_NAME -X stuff "`printf "reload\r"`"
							printf "Attempted to reload the server, check the console to see how that worked out.\n"
						elif [ "$ANSWER" = "N" ] || [ "$ANSWER" = "n" ]; then
							printf "You opted not to reload.\n"
						else
							printf "The script did not understand what you wrote. But we will assume you meant no.\n"
						fi
					else
						printf "Something really weird happened. The script will proceed to dump some information to help debug.\n"
						printf "The server version that was read was: $SERVER_VERSION\n"
						printf "The version number that was obtained from the website was: $WEBSITE_VERSION\n"
						printf "Please submit this bug on my Github page, including the information dump, or simply try the script again.\n"
						exit 0
					fi
			elif [ "$update_opt" = "Essentials" ]; then
				WEBSITE_VERSION=`lynx -dump http://irc.donclurd.com/${update_opt}.txt`
				LOG_LINES=`cat server.log | grep 'Loaded Essentials build' | wc -l`
				SERVER_VERSION=`cat $MC_DIR/server.log | grep 'Loaded Essentials build' | sed -n ${LOG_LINES}p | awk '{printf $7}'`
					if [ "$SERVER_VERSION" = "$WEBSITE_VERSION" ]; then
						printf "It appears your Essentials version, $SERVER_VERSION, is up to date with the latest version, $WEBSITE_VERSION.\n"
					elif [ "$SERVER_VERSION" != "$WEBSITE_VERSION" ]; then
						printf "It seems your Essentials installation is out of date. Current: $SERVER_VERSION New: $WEBSITE_VERSION\n"
						printf "If anything but two version numbers came out (e.g. asdf instead of 2.6.4) then interrupt the script via CTRL+C and attempt again.\n"
						sleep 0.5

						printf "Do you want to reload the server to attempt to upgrade now? Please answer Y or N.\nReload:"
						read ANSWER
						if [ "$ANSWER" = "Y" || "$ANSWER" = "y" ]; then
							screen -p 0 -S $SCREEN_NAME -X stuff "`printf "reload\r"`"
							printf "Attempted to reload the server, check the console to see how that worked out.\n"
						elif [ "$ANSWER" = "N" || "$ANSWER" = "n" ]; then
							printf "You opted not to reload.\n"
						else
							printf "The script did not understand what you wrote. But we will assume you meant no.\n"
						fi
					else
						printf "Something really weird happened. The script will proceed to dump some information to help debug.\n"
						printf "The server version that was read was: $SERVER_VERSION\n"
						printf "The version number that was obtained from the website was: $WEBSITE_VERSION\n"
						printf "Please submit this bug on my Github page, including the information dump, or simply try the script again.\n"
						exit 0
					fi
			else
				printf "Please select an option.\n"
			fi
		done
	elif [ "$opt" = "Remove" ]; then
		REMOVE_OPTIONS="WorldGuard WorldEdit Essentials"
		select remove_opt in $REMOVE_OPTIONS; do
			if [ "$remove_opt" = "WorldGuard" ]; then
				printf "Removing WorldGuard.\n"
				printf "If this is unintentional you have 3 seconds to terminate this script, using CTRL+C.\n"
				sleep 3
				rm -r $MC_DIR/plugins/WorldGuard/
				rm $MC_DIR/plugins/WorldGuard.jar
				printf "Attempted to remove WorldGuard.\n"
				printf "Do you want to reload the server to attempt to commit the removal now? Please answer 'Y' or 'N'.\nReload:"
				read ANSWER
				if [ "$ANSWER" = "Y" || "$ANSWER" = "y" ]; then
					screen -p 0 -S $SCREEN_NAME -X stuff "`printf "reload\r"`"
					printf "Attempted to reload the server, check the console to see how that worked out.\n"
				elif [ "$ANSWER" = "N" || "$ANSWER" = "n" ]; then
					printf "You opted not to reload.\n"
				else
					printf "The script did not understand what you wrote. But we will assume you meant 'no'.\n"
				fi
			elif [ "$remove_opt" = "WorldEdit" ]; then
				printf "Removing WorldEdit.\n"
				printf "If this is unintentional, you have 3 seconds to terminate this script, using CTRL+C.\n"
				sleep 3
				rm -r $MC_DIR/plugins/WorldEdit/
				rm $MC_DIR/plugins/WorldEdit.jar
				rm -r $MC_DIR/craftscripts/
				printf "Attempted to remove WorldEdit in its entirity.\n"
				printf "Do you want to reload the server to attempt to commit the removal now? Please answer 'Y' or 'N'.\nReload:"
				read ANSWER
				if [ "$ANSWER" = "Y" || "$ANSWER" = "y" ]; then
					screen -p 0 -S $SCREEN_NAME -X stuff "`printf "reload\r"`"
					printf "Attempted to reload the server, check the console to see how that worked out.\n"
				elif [ "$ANSWER" = "N" || "$ANSWER" = "n" ]; then
					printf "You opted not to reload.\n"
				else
					printf "The script did not understand what you wrote. But we will assume you meant 'no'.\n"
				fi
			elif [ "$remove_opt" = "Essentials" ]; then
				printf "Removing Essentials.\n"
				printf "If this is unintentional, you have 3 seconds to terminate this script, using CTRL+C.\n"
				sleep 3
				rm -r $MC_DIR/plugins/Essentials/
				rm $MC_DIR/plugins/Essentials*
				printf "Attempted to remove Essentials.\n"
				printf "Do you want to reload the server to attempt to commit the removal now? Please answer 'Y' or 'N'.\nReload:"
				read ANSWER
				if [ "$ANSWER" = "Y" || "$ANSWER" = "y" ]; then
					screen -p 0 -S $SCREEN_NAME -X stuff "`printf "reload\r"`"
					printf "Attempted to reload the server, check the console to see how that worked out.\n"
				elif [ "$ANSWER" = "N" || "$ANSWER" = "n" ]; then
					printf "You opted not to reload.\n"
				else
					printf "The script did not understand what you wrote. But we will assume you meant 'no'.\n"
				fi
			else
				printf "Something went wrong and the script did not understand your input. Please try again.\n"
			fi
		done
	elif [ "$opt" = "Check" ]; then
		CHECK_OPTIONS="WorldGuard WorldEdit Essentials"
		select check_opt in $CHECK_OPTIONS; do
			if [ "$check_opt" = "WorldGuard" ]; then
				printf "Checking if WorldGuard is the latest version.\n"
				WEBSITE_VERSION=`lynx -dump http://irc.donclurd.com/worldguard-version.txt`
				LOG_LINES=`cat $MC_DIR/server.log | grep 'WorldGuard' | grep 'enabled.' | wc -l`
				SERVER_VERSION=`cat $MC_DIR/server.log | grep 'WorldGuard' | grep 'enabled.' | sed -n ${LOG_LINES}p | awk '{printf $5}'`
				if [ "$SERVER_VERSION" = "$WEBSITE_VERSION" ]; then
					printf "It appears your WorldGuard version, $SERVER_VERSION, is up to date with the response from the website, $WEBSITE_VERSION.\n"
				elif [ "$SERVER_VERSION" != "$WEBSITE_VERSION" ]; then
					printf "Your version is out of date, latest version $WEBSITE_VERSION and your version $SERVER_VERSION.\n"
				else
					printf "Something unexpected happened.\n"
				fi
			elif [ "$check_opt" = "WorldEdit" ]; then
				WEBSITE_VERSION=`lynx -dump http://irc.donclurd.com/worldedit-version.txt`
				LOG_LINES=`cat $MC_DIR/server.log | grep 'WorldEdit' | grep 'enabled.' | wc -l`
				SERVER_VERSION=`cat $MC_DIR/server.log | grep 'WorldEdit' | grep 'enabled.' | sed -n ${LOG_LINES}p | awk '{printf $5}'`
				if [ "$SERVER_VERSION" = "$WEBSITE_VERSION" ]; then
					printf "It appears your WorldEdit version, $SERVER_VERSION, is up to date with the latest version, $WEBSITE_VERSION.\n"
				elif [ "$SERVER_VERSION" != "$WEBSITE_VERSION" ]; then
					printf "It seems your WorldEdit installation is out of date. Current: $SERVER_VERSION New: $WEBSITE_VERSION\n"
				else
					printf "Something unexpected happened.\n"
				fi
			elif [ "$check_opt" = "Essentials" ]; then
				WEBSITE_VERSION=`lynx -dump http://irc.donclurd.com/essentials.txt`
				LOG_LINES=`cat server.log | grep 'Loaded Essentials build' | wc -l`
				SERVER_VERSION=`cat $MC_DIR/server.log | grep 'Loaded Essentials build' | sed -n ${LOG_LINES}p | awk '{printf $7}'`
					if [ "$SERVER_VERSION" = "$WEBSITE_VERSION" ]; then
						printf "It appears your Essentials version, $SERVER_VERSION, is up to date with the latest version, $WEBSITE_VERSION.\n"
					elif [ "$SERVER_VERSION" != "$WEBSITE_VERSION" ]; then
						printf "It seems your Essentials installation is out of date. Current: $SERVER_VERSION New: $WEBSITE_VERSION\n"
					else
						printf "Something unexpected happened.\n"
					fi
			else
				printf "Please select an option.\n"
			fi
		done
	fi
done