#!/bin/bash
SOURCE_DIR=`cat backup.conf | grep -w Backup-source: | awk '{print $2}'`
DESTINATION_DIR=`cat backup.conf | grep -w Backup-destination: | awk '{printf $2}'`
SCREEN_NAME=`cat backup.conf | grep -w Screen-name: | awk '{print $2}'`
ANNOUNCE_BACKUP=`cat backup.conf | grep -w Backup-Announce: | awk '{print $2}'`
LOG=`cat backup.conf | grep -w Log-location: | awk '{print $2}'`
BACKUP_TOOL=`cat backup.conf | grep -w Backup-program: | awk '{print $2}'`
MENU_OPTIONS="Backup Restore Purge/Delete Quit"
TIMESTAMP=`cat backup.conf | grep -w 'Timestamp-format:' | cut -d ' ' -f2`
select opt in $MENU_OPTIONS; do
	if [ "$opt" = "Backup" ]; then
		START_TIME=$(date +%s)
		printf "Beginning backup from $SOURCE_DIR to $DESTINATION_DIR.\n"
		if [ "$ANNOUNCE_BACKUP" = "true" ]; then
			screen -p 0 -S $SCREEN_NAME -X stuff "`printf "say Starting backup!\r"`"
		elif [ "$ANNOUNCE_BACKUP" = "false" ]; then
			printf "$TIMESTAMP: Serverwide announciation disabled.\n"
		else
			printf "[$TIMESTAMP Warning]: Backup-Announce: in backup.conf is set to something other than true or false. As this is not essential the script won't fail but will not announce backups either.\n"
		fi
		screen -p 0 -S $SCREEN_NAME -X stuff "`printf "save-all\r"`"
		screen -p 0 -S $SCREEN_NAME -X stuff "`printf "save-off\r"`"
		# Sleep to give the server time to catchup as some slower servers can have trouble with save-all.
		sleep 1
		if [ "$BACKUP_TOOL" = "rdiff-backup" ]; then
			printf "Starting rdiff-backup at $TIMESTAMP\n" >> $LOG
			rdiff-backup -v0 --print-statistics $SOURCE_DIR $DESTINATION_DIR >> $LOG
			END_TIME=$(date +%s)
			DIFF=$(( $END_TIME - $START_TIME ))
			printf "Finished rdiff-backup at $TIMESTAMP\n" >> $LOG
			printf "Backup took $DIFF seconds to complete.\n" >> $LOG
		elif [ "$BACKUP_TOOL" = "tar" ]: then
			printf "Starting tar at $TIMESTAMP\n" >> $LOG
			tar -czvf $DESTINATION_DIR$TIMESTAMP.tar.gz $SOURCE_DIR >> $LOG
			END_TIME=$(date +%s)
			DIFF=$(( $END_TIME - $START_TIME ))
			printf "Finished tar at $TIMESTAMP\n" >> $LOG
			printf "Backup tool $DIFF seconds to complete.\n" >> $LOG
		else
			printf "Backup-program: option has been incorrectly configured in backup.conf. This script will continue to fail until it is fixed to only contain tar or rdiff-backup.\n"
			exit 0
		fi
		if [ "$ANNOUNCE_BACKUP" = "true" ]; then
			screen -p 0 -S $SCREEN_NAME -X stuff "`printf "say Backup complete.\r"`"
			screen -p 0 -S $SCREEN_NAME -X stuff "`printf "say Backup took $DIFF seconds to complete.\r"`"
		else
			printf ""
		fi
		screen -p 0 -S $SCREEN_NAME -X stuff "`printf "save-all\r"`"
		screen -p 0 -S $SCREEN_NAME -X stuff "`printf "save-on\r"`"
		exit 0
	elif [ "$opt" = "Restore" ]; then
		printf "Did you use rdiff-backup or tar for the backup you wish to restore?\nTool:"
		read APPLICATION
		if [ "$APPLICATION" = "tar" ]; then
			cd $DESTINATION_DIR
			# Credit where credit is due, I did not write this, this is an adaptation from http://www.linuxquestions.org/questions/linux-newbie-8/bash-script-help-menu-to-pick-file-from-folder-623052/#post3070195 who's script was useful enough for this.
			tarballs=(*.tar.gz)
			for (( i=0; i<${#tarballs[*]}; i++ )); do
			echo $i: ${tarballs[$i]}
			done
			read -ep "Which one? "
			echo xzvf ${tarballs[$REPLY]} >> $LOG
			exit 0
		elif [ "$APPLICATION" = "rdiff-backup" ]; then
			printf "Please specify the date of the backup you wish to restore, if you want to restore a recent backup such as one that may have occured one or two backups ago you would specify 1B or 2B.\n"
			printf "Unfortunately this uses W3 time formatting which is the United States stuff of MM-DD-YYYY, for those of us who are unfamiliar just bear with me :(\n"
			printf "Specify date like this: YYYY-MM-DDTHH\n"
			printf "Where it is year-month-dayTHour\n.Date:"
			read RESTORE_TIME
			printf "What directory do you want the backup to go to?\n"
			read BACKUP_DESTINATION_DIR
			rdiff-backup -r $RESTORE_TIME $DESTINATION_DIR $BACKUP_DESTINATION_DIR
			printf "A backup should now be in $BACKUP_DESTINATION_DIR.\n"
			exit 0
		else
			printf "It appears your words did not match rdiff-backup or tar. Please try again.\n"
			exit 0
		fi
		exit 0
	elif [ "$opt" = "Purge/Delete" ]; then
		if [ "$BACKUP_TOOL" = "rdiff-backup" ]; then
			printf "How far back do you want files removed? e.g. removing files older than 1 week, 2 months, 7 days and 13 hours ago would work like 1W2M7D13h additional information at http://minecraft.donclurd.com/scripts/removeolder.html\n"
			read DELETE_DATE
			rdiff-backup --remove-older-than $DELETE_DATE $DESTINATION_DIR
			printf "Attempted to remove the older diffs from your backup folder.\n"
			exit 0
		elif [ "$BACKUP_TOOL" = "tar" ]; then
			printf "Specify how far back you want archives deleted in hours.\nHour:"
			read DELETE_DATE
			find $DESTINATION_DIR -name "*tar.gz" -type f -Btime +$DELTE_DATE -delete
			printf "Attempted to remove all .tar.gz files that are older than $DELTE_DATE hours in $DESTINATION_DIR.\n"
		else
			printf "Backup-program: is incorrectly set, set to either rdiff-backup or tar for this script to work properly.\n"
			exit 0
	elif [ "$opt" = "Quit" ]; then
		exit 0
	fi
done