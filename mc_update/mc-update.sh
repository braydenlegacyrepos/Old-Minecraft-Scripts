#!/bin/bash
MC_DIR=`cat mc-update.conf | grep -w 'Minecraft_dir:' | awk '{printf $2}'`
SCREEN_NAME=`cat mc-update.conf | grep -w 'Screen_name:' | awk '{printf $2}'`
MENU_OPTIONS="Update Remove Version"
select opt in $MENU_OPTIONS; do
	if [ "$opt" = "Update" ]; then
		UPDATE_OPTIONS="WorldGuard WorldEdit Essentials"
		select update_opt in $UPDATE_OPTIONS; do
			if [ "$update_opt" = "WorldGuard" ]; then
				WEBSITE_VERSION=`lynx -dump http://dev.bukkit.org/server-mods/worldguard/ | \grep 'R:' | awk '{printf $4}'`
				LOG_LINES=`cat $MC_DIR/server.log | grep 'WorldGuard' | grep 'enabled.' | wc -l`
				SERVER_VERSION=`cat $MC_DIR/server.log | grep 'WorldGuard' | grep 'enabled.' | sed -n ${LOG_LINES}p | awk '{printf $5}'`
					if [ "$SERVER_VERSION" = "$WEBSITE_VERSION" ]; then
						printf "It appears your WorldGuard version, $SERVER_VERSION, is up to date with the response from the website, $WEBSITE_VERSIon.\n"
						exit 0
					elif [ "$SERVER_VERSION" != "$WEBSITE_VERSION" ]; then
						printf "Your version is out of date, latest version $WEBSITE_VERSION and your version $SERVER_VERSION.\n"
						printf "Figuring out the link to the new version, you may see some curl output which is just the script attempting to 'intelligently' determine the URL.\n"
						STEP_1=`curl http://dev.bukkit.org/server-mods/worldguard/ | ./list_urls.sed | grep -w 'files/1-world-guard'`
						STEP_2=`http://dev.bukkit.org${STEP_1} | ./list_urls.sed | grep -w 'worldguard' | grep -w 'files' | sed -n 2p`
						printf "Making temporary directory.\n"
						mkdir ~/worldguard_tmp/
						printf "Downloading WorldGuard.\n"
						wget --output-document=~/worldguard_tmp/worldguard.zip $STEP_2
						printf "Unpacking WorldGuard to the temporary folder.\n"
						unzip ~/worldguard_tmp/worldguard.zip > /dev/null
						printf "Copying WorldGuard.jar into the server's plugins directory.\n"
						cp ~/worldguard_tmp/WorldGuard.jar $MC_DIR/plugins/WorldGuard.jar
						printf "Cleaning up the temporary directory.\n"
						rm -r ~/worldguard_tmp/
						printf "Do you want to reload the server to attempt to upgrade now? Please answer 'Y' or 'N'.\nReload:"
						read ANSWER
						if [ "$ANSWER" = "Y" || "$ANSWER" = "y" ]; then
							screen -p 0 -S $SCREEN_NAME -X stuff "`printf "reload\r"`"
							printf "Attempted to reload the server, check the console to see how that worked out.\n"
							printf "Script has nothing else to do now and will quit.\n"
							exit 0
						elif [ "$ANSWER" = "N" || "$ANSWER" = "n" ]; then
							printf "You opted not to reload.\n"
							exit 0
						else
							printf "The script did not understand what you wrote.\n"
							exit 0
						fi
			elif [ "$update_opt" = "WorldEdit" ]; then
				WEBSITE_VERSION=`lynx -dump http://dev.bukkit.org/server-mods/worldedit/ | \grep 'R:' | sed -n 1p | awk '{printf $4}'`
				