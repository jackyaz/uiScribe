#!/bin/sh

######################################################
##                                                  ##
##          _   _____              _  _             ##
##         (_) / ____|            (_)| |            ##
##   _   _  _ | (___    ___  _ __  _ | |__    ___   ##
##  | | | || | \___ \  / __|| '__|| || '_ \  / _ \  ##
##  | |_| || | ____) || (__ | |   | || |_) ||  __/  ##
##   \__,_||_||_____/  \___||_|   |_||_.__/  \___|  ##
##                                                  ##
##        https://github.com/jackyaz/uiScribe       ##
##                                                  ##
######################################################

### Start of script variables ###
readonly SCRIPT_NAME="uiScribe"
readonly SCRIPT_VERSION="v1.4.1"
readonly SCRIPT_BRANCH="master"
readonly SCRIPT_REPO="https://raw.githubusercontent.com/jackyaz/$SCRIPT_NAME/$SCRIPT_BRANCH"
readonly SCRIPT_DIR="/jffs/addons/$SCRIPT_NAME.d"
readonly SCRIPT_CONF="$SCRIPT_DIR/config"
readonly SCRIPT_PAGE_DIR="$(readlink /www/user)"
readonly SCRIPT_WEB_DIR="$SCRIPT_PAGE_DIR/$SCRIPT_NAME"
readonly SHARED_DIR="/jffs/addons/shared-jy"
readonly SHARED_REPO="https://raw.githubusercontent.com/jackyaz/shared-jy/master"
readonly SHARED_WEB_DIR="$SCRIPT_PAGE_DIR/shared-jy"
[ -z "$(nvram get odmpid)" ] && ROUTER_MODEL=$(nvram get productid) || ROUTER_MODEL=$(nvram get odmpid)
### End of script variables ###

### Start of output format variables ###
readonly CRIT="\\e[41m"
readonly ERR="\\e[31m"
readonly WARN="\\e[33m"
readonly PASS="\\e[32m"
### End of output format variables ###

# $1 = print to syslog, $2 = message to print, $3 = log level
Print_Output(){
	if [ "$1" = "true" ]; then
		logger -t "$SCRIPT_NAME" "$2"
		printf "\\e[1m$3%s: $2\\e[0m\\n\\n" "$SCRIPT_NAME"
	else
		printf "\\e[1m$3%s: $2\\e[0m\\n\\n" "$SCRIPT_NAME"
	fi
}

### Code for these functions inspired by https://github.com/Adamm00 - credit to @Adamm ###
Check_Lock(){
	if [ -f "/tmp/$SCRIPT_NAME.lock" ]; then
		ageoflock=$(($(date +%s) - $(date +%s -r /tmp/$SCRIPT_NAME.lock)))
		if [ "$ageoflock" -gt 600 ]; then
			Print_Output true "Stale lock file found (>600 seconds old) - purging lock" "$ERR"
			kill "$(sed -n '1p' /tmp/$SCRIPT_NAME.lock)" >/dev/null 2>&1
			Clear_Lock
			echo "$$" > "/tmp/$SCRIPT_NAME.lock"
			return 0
		else
			Print_Output true "Lock file found (age: $ageoflock seconds) - stopping to prevent duplicate runs" "$ERR"
			if [ -z "$1" ]; then
				exit 1
			else
				return 1
			fi
		fi
	else
		echo "$$" > "/tmp/$SCRIPT_NAME.lock"
		return 0
	fi
}

Clear_Lock(){
	rm -f "/tmp/$SCRIPT_NAME.lock" 2>/dev/null
	return 0
}
############################################################################

Set_Version_Custom_Settings(){
	SETTINGSFILE=/jffs/addons/custom_settings.txt
	case "$1" in
		local)
			if [ -f "$SETTINGSFILE" ]; then
				if [ "$(grep -c "uiscribe_version_local" $SETTINGSFILE)" -gt 0 ]; then
					if [ "$SCRIPT_VERSION" != "$(grep "uiscribe_version_local" /jffs/addons/custom_settings.txt | cut -f2 -d' ')" ]; then
						sed -i "s/uiscribe_version_local.*/uiscribe_version_local $SCRIPT_VERSION/" "$SETTINGSFILE"
					fi
				else
					echo "uiscribe_version_local $SCRIPT_VERSION" >> "$SETTINGSFILE"
				fi
			else
				echo "uiscribe_version_local $SCRIPT_VERSION" >> "$SETTINGSFILE"
			fi
		;;
		server)
			if [ -f "$SETTINGSFILE" ]; then
				if [ "$(grep -c "uiscribe_version_server" $SETTINGSFILE)" -gt 0 ]; then
					if [ "$2" != "$(grep "uiscribe_version_server" /jffs/addons/custom_settings.txt | cut -f2 -d' ')" ]; then
						sed -i "s/uiscribe_version_server.*/uiscribe_version_server $2/" "$SETTINGSFILE"
					fi
				else
					echo "uiscribe_version_server $2" >> "$SETTINGSFILE"
				fi
			else
				echo "uiscribe_version_server $2" >> "$SETTINGSFILE"
			fi
		;;
	esac
}

Update_Check(){
	echo 'var updatestatus = "InProgress";' > "$SCRIPT_WEB_DIR/detect_update.js"
	doupdate="false"
	localver=$(grep "SCRIPT_VERSION=" /jffs/scripts/"$SCRIPT_NAME" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
	/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep -qF "jackyaz" || { Print_Output true "404 error detected - stopping update" "$ERR"; return 1; }
	serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
	if [ "$localver" != "$serverver" ]; then
		doupdate="version"
		Set_Version_Custom_Settings server "$serverver"
		echo 'var updatestatus = "'"$serverver"'";'  > "$SCRIPT_WEB_DIR/detect_update.js"
	else
		localmd5="$(md5sum "/jffs/scripts/$SCRIPT_NAME" | awk '{print $1}')"
		remotemd5="$(curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | md5sum | awk '{print $1}')"
		if [ "$localmd5" != "$remotemd5" ]; then
			doupdate="md5"
			Set_Version_Custom_Settings server "$serverver-hotfix"
			echo 'var updatestatus = "'"$serverver-hotfix"'";'  > "$SCRIPT_WEB_DIR/detect_update.js"
		fi
	fi
	if [ "$doupdate" = "false" ]; then
		echo 'var updatestatus = "None";'  > "$SCRIPT_WEB_DIR/detect_update.js"
	fi
	echo "$doupdate,$localver,$serverver"
}

Update_Version(){
	if [ -z "$1" ] || [ "$1" = "unattended" ]; then
		updatecheckresult="$(Update_Check)"
		isupdate="$(echo "$updatecheckresult" | cut -f1 -d',')"
		localver="$(echo "$updatecheckresult" | cut -f2 -d',')"
		serverver="$(echo "$updatecheckresult" | cut -f3 -d',')"
		
		if [ "$isupdate" = "version" ]; then
			Print_Output true "New version of $SCRIPT_NAME available - updating to $serverver" "$PASS"
		elif [ "$isupdate" = "md5" ]; then
			Print_Output true "MD5 hash of $SCRIPT_NAME does not match - downloading updated $serverver" "$PASS"
		fi
		
		Update_File shared-jy.tar.gz
		
		if [ "$isupdate" != "false" ]; then
			Update_File Main_LogStatus_Content.asp
			
			/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output true "$SCRIPT_NAME successfully updated"
			chmod 0755 /jffs/scripts/"$SCRIPT_NAME"
			Clear_Lock
			if [ -z "$1" ]; then
				exec "$0" setversion
			elif [ "$1" = "unattended" ]; then
				exec "$0" setversion unattended
			fi
			exit 0
		else
			Print_Output true "No new version - latest is $localver" "$WARN"
			Clear_Lock
		fi
	fi
	
	if [ "$1" = "force" ]; then
		serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
		Print_Output true "Downloading latest version ($serverver) of $SCRIPT_NAME" "$PASS"
		Update_File Main_LogStatus_Content.asp
		Update_File shared-jy.tar.gz
		/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME.sh" -o "/jffs/scripts/$SCRIPT_NAME" && Print_Output true "$SCRIPT_NAME successfully updated"
		chmod 0755 /jffs/scripts/"$SCRIPT_NAME"
		Clear_Lock
		if [ -z "$2" ]; then
			exec "$0" setversion
		elif [ "$2" = "unattended" ]; then
			exec "$0" setversion unattended
		fi
		exit 0
	fi
}

Update_File(){
	if [ "$1" = "Main_LogStatus_Content.asp" ]; then
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		if ! diff -q "$tmpfile" "$SCRIPT_DIR/$1" >/dev/null 2>&1; then
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
			Print_Output true "New version of $1 downloaded" "$PASS"
			Mount_WebUI
		fi
		rm -f "$tmpfile"
	elif [ "$1" = "shared-jy.tar.gz" ]; then
		if [ ! -f "$SHARED_DIR/$1.md5" ]; then
			Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
			Download_File "$SHARED_REPO/$1.md5" "$SHARED_DIR/$1.md5"
			tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
			rm -f "$SHARED_DIR/$1"
			Print_Output true "New version of $1 downloaded" "$PASS"
		else
			localmd5="$(cat "$SHARED_DIR/$1.md5")"
			remotemd5="$(curl -fsL --retry 3 "$SHARED_REPO/$1.md5")"
			if [ "$localmd5" != "$remotemd5" ]; then
				Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
				Download_File "$SHARED_REPO/$1.md5" "$SHARED_DIR/$1.md5"
				tar -xzf "$SHARED_DIR/$1" -C "$SHARED_DIR"
				rm -f "$SHARED_DIR/$1"
				Print_Output true "New version of $1 downloaded" "$PASS"
			fi
		fi
	else
		return 1
	fi
}

Validate_Number(){
	if [ "$2" -eq "$2" ] 2>/dev/null; then
		return 0
	else
		formatted="$(echo "$1" | sed -e 's/|/ /g')"
		if [ -z "$3" ]; then
			Print_Output false "$formatted - $2 is not a number" "$ERR"
		fi
		return 1
	fi
}

Create_Dirs(){
	if [ ! -d "$SCRIPT_DIR" ]; then
		mkdir -p "$SCRIPT_DIR"
	fi
	
	if [ ! -d "$SHARED_DIR" ]; then
		mkdir -p "$SHARED_DIR"
	fi
	
	if [ ! -d "$SCRIPT_WEB_DIR" ]; then
		mkdir -p "$SCRIPT_WEB_DIR"
	fi
}

Create_Symlinks(){
	syslog-ng --preprocess-into="$SCRIPT_DIR/tmplogs.txt" && grep -A 1 "destination" "$SCRIPT_DIR/tmplogs.txt" | grep "file(\"" | grep -v "#" | grep -v "messages" | sed -e 's/file("//;s/".*$//' | awk '{$1=$1;print}' > "$SCRIPT_DIR/.logs"
	rm -f "$SCRIPT_DIR/tmplogs.txt" 2>/dev/null
	
	if [ "$1" = "force" ]; then
		rm -f "$SCRIPT_DIR/.logs_user"
	fi
	
	if [ ! -f "$SCRIPT_DIR/.logs_user" ]; then
		touch "$SCRIPT_DIR/.logs_user"
	fi
	
	while IFS='' read -r line || [ -n "$line" ]; do
		if [ "$(grep -c "$line" "$SCRIPT_DIR/.logs_user")" -eq 0 ]; then
				printf "%s\\n" "$line" >> "$SCRIPT_DIR/.logs_user"
		fi
	done < "$SCRIPT_DIR/.logs"
	
	rm -f "$SCRIPT_WEB_DIR/"*.htm 2>/dev/null
	ln -s "$SCRIPT_DIR/.logs_user" "$SCRIPT_WEB_DIR/logs.htm" 2>/dev/null
	ln -s /opt/var/log/messages "$SCRIPT_WEB_DIR/messages.htm" 2>/dev/null
	while IFS='' read -r line || [ -n "$line" ]; do
		ln -s "$line" "$SCRIPT_WEB_DIR/$(basename "$line").htm" 2>/dev/null
	done < "$SCRIPT_DIR/.logs"
	
	if [ ! -d "$SHARED_WEB_DIR" ]; then
		ln -s "$SHARED_DIR" "$SHARED_WEB_DIR" 2>/dev/null
	fi
}

Logs_FromSettings(){
	SETTINGSFILE="/jffs/addons/custom_settings.txt"
	LOGS_USER="$SCRIPT_DIR/.logs_user"
	if [ -f "$SETTINGSFILE" ]; then
		if grep -q "uiscribe_logs_enabled" "$SETTINGSFILE"; then
			Print_Output true "Updated logs from WebUI found, merging into $LOGS_USER" "$PASS"
			cp -a "$LOGS_USER" "$LOGS_USER.bak"
			SETTINGVALUE="$(grep "uiscribe_logs_enabled" "$SETTINGSFILE" | cut -f2 -d' ')"
			sed -i "\\~uiscribe_logs_enabled~d" "$SETTINGSFILE"
			
			syslog-ng --preprocess-into="$SCRIPT_DIR/tmplogs.txt" && grep -A 1 "destination" "$SCRIPT_DIR/tmplogs.txt" | grep "file(\"" | grep -v "#" | grep -v "messages" | sed -e 's/file("//;s/".*$//' | awk '{$1=$1;print}' > "$SCRIPT_DIR/.logs"
			rm -f "$SCRIPT_DIR/tmplogs.txt" 2>/dev/null
			
			echo "" > "$LOGS_USER"
			
			comment=" #excluded#"
			while IFS='' read -r line || [ -n "$line" ]; do
				if [ "$(grep -c "$line" "$LOGS_USER")" -eq 0 ]; then
						printf "%s%s\\n" "$line" "$comment" >> "$LOGS_USER"
				fi
			done < "$SCRIPT_DIR/.logs"
			
			for log in $(echo "$SETTINGVALUE" | sed "s/,/ /g"); do
				loglinenumber="$(grep -n "$log" "$LOGS_USER" | cut -f1 -d':')"
				logline="$(sed "$loglinenumber!d" "$LOGS_USER" | awk '{$1=$1};1')"
				
				if echo "$logline" | grep -q "#excluded" ; then
					sed -i "$loglinenumber"'s/ #excluded#//' "$LOGS_USER"
				fi
			done
			
			awk 'NF' "$LOGS_USER" > /tmp/uiscribe-logs
			mv /tmp/uiscribe-logs "$LOGS_USER"
			
			rm -f "$SCRIPT_WEB_DIR/"*.htm 2>/dev/null
			ln -s "$SCRIPT_DIR/.logs_user" "$SCRIPT_WEB_DIR/logs.htm" 2>/dev/null
			ln -s /opt/var/log/messages "$SCRIPT_WEB_DIR/messages.htm" 2>/dev/null
			while IFS='' read -r line || [ -n "$line" ]; do
				ln -s "$line" "$SCRIPT_WEB_DIR/$(basename "$line").htm" 2>/dev/null
			done < "$SCRIPT_DIR/.logs"
			
			Print_Output true "Merge of updated logs from WebUI completed successfully" "$PASS"
		else
			Print_Output true "No updated logs from WebUI found, no merge into $LOGS_USER necessary" "$PASS"
		fi
	fi
}

Generate_Log_List(){
	ScriptHeader
	goback="false"
	printf "Retrieving list of log files...\\n\\n"
	logcount="$(wc -l < "$SCRIPT_DIR/.logs_user")"
	COUNTER=1
	until [ "$COUNTER" -gt "$logcount" ]; do
		logfile="$(sed "$COUNTER!d" "$SCRIPT_DIR/.logs_user" | awk '{$1=$1};1')"
		if [ "$COUNTER" -lt 10 ]; then
			printf "%s)  %s\\n" "$COUNTER" "$logfile"
		else
			printf "%s) %s\\n" "$COUNTER" "$logfile"
		fi
		COUNTER=$((COUNTER + 1))
	done
	
	printf "\\ne)  Go back\\n"
	
	while true; do
	printf "\\n\\e[1mPlease select a log to toggle inclusion in %s (1-%s):\\e[0m\\n" "$SCRIPT_NAME" "$logcount"
	read -r log
	
	if [ "$log" = "e" ]; then
		goback="true"
		break
	elif ! Validate_Number "" "$log" silent; then
		printf "\\n\\e[31mPlease enter a valid number (1-%s)\\e[0m\\n" "$logcount"
	else
		if [ "$log" -lt 1 ] || [ "$log" -gt "$logcount" ]; then
			printf "\\n\\e[31mPlease enter a number between 1 and %s\\e[0m\\n" "$logcount"
		else
			logline="$(sed "$log!d" "$SCRIPT_DIR/.logs_user" | awk '{$1=$1};1')"
			if echo "$logline" | grep -q "#excluded#" ; then
					sed -i "$log"'s/ #excluded#//' "$SCRIPT_DIR/.logs_user"
			else
				sed -i "$log"'s/$/ #excluded#/' "$SCRIPT_DIR/.logs_user"
			fi
			sed -i 's/ *$//' "$SCRIPT_DIR/.logs_user"
			printf "\\n"
			break
		fi
	fi
	done
	
	if [ "$goback" != "true" ]; then
		Generate_Log_List
	fi
}

Auto_ServiceEvent(){
	case $1 in
		create)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)
				# shellcheck disable=SC2016
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME service_event"' "$@" & # '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					# shellcheck disable=SC2016
					echo "/jffs/scripts/$SCRIPT_NAME service_event"' "$@" & # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/service-event
				echo "" >> /jffs/scripts/service-event
				# shellcheck disable=SC2016
				echo "/jffs/scripts/$SCRIPT_NAME service_event"' "$@" & # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				chmod 0755 /jffs/scripts/service-event
			fi
		;;
		delete)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
			fi
		;;
	esac
}

Auto_Startup(){
	case $1 in
		create)
			if [ -f /jffs/scripts/services-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/services-start)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/services-start
				fi
			fi
			if [ -f /jffs/scripts/post-mount ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/post-mount)
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME startup"' "$@" & # '"$SCRIPT_NAME" /jffs/scripts/post-mount)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/post-mount
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo "/jffs/scripts/$SCRIPT_NAME startup"' "$@" & # '"$SCRIPT_NAME" >> /jffs/scripts/post-mount
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/post-mount
				echo "" >> /jffs/scripts/post-mount
				echo "/jffs/scripts/$SCRIPT_NAME startup"' "$@" & # '"$SCRIPT_NAME" >> /jffs/scripts/post-mount
				chmod 0755 /jffs/scripts/post-mount
			fi
		;;
		delete)
			if [ -f /jffs/scripts/services-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/services-start)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/services-start
				fi
			fi
			if [ -f /jffs/scripts/post-mount ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/post-mount)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/post-mount
				fi
			fi
		;;
	esac
}

Download_File(){
	/usr/sbin/curl -fsL --retry 3 "$1" -o "$2"
}

Mount_WebUI(){
	umount /www/Main_LogStatus_Content.asp 2>/dev/null
	
	mount -o bind "$SCRIPT_DIR/Main_LogStatus_Content.asp" /www/Main_LogStatus_Content.asp
}

Shortcut_script(){
	case $1 in
		create)
			if [ -d /opt/bin ] && [ ! -f "/opt/bin/$SCRIPT_NAME" ] && [ -f "/jffs/scripts/$SCRIPT_NAME" ]; then
				ln -s /jffs/scripts/"$SCRIPT_NAME" /opt/bin
				chmod 0755 /opt/bin/"$SCRIPT_NAME"
			fi
		;;
		delete)
			if [ -f "/opt/bin/$SCRIPT_NAME" ]; then
				rm -f /opt/bin/"$SCRIPT_NAME"
			fi
		;;
	esac
}

PressEnter(){
	while true; do
		printf "Press enter to continue..."
		read -r key
		case "$key" in
			*)
				break
			;;
		esac
	done
	return 0
}

ScriptHeader(){
	clear
	printf "\\n"
	printf "\\e[1m######################################################\\e[0m\\n"
	printf "\\e[1m##                                                  ##\\e[0m\\n"
	printf "\\e[1m##          _   _____              _  _             ##\\e[0m\\n"
	printf "\\e[1m##         (_) / ____|            (_)| |            ##\\e[0m\\n"
	printf "\\e[1m##   _   _  _ | (___    ___  _ __  _ | |__    ___   ##\\e[0m\\n"
	printf "\\e[1m##  | | | || | \___ \  / __|| '__|| || '_ \  / _ \  ##\\e[0m\\n"
	printf "\\e[1m##  | |_| || | ____) || (__ | |   | || |_) ||  __/  ##\\e[0m\\n"
	printf "\\e[1m##   \__,_||_||_____/  \___||_|   |_||_.__/  \___|  ##\\e[0m\\n"
	printf "\\e[1m##                                                  ##\\e[0m\\n"
	printf "\\e[1m##               %s on %-9s                ##\\e[0m\\n" "$SCRIPT_VERSION" "$ROUTER_MODEL"
	printf "\\e[1m##                                                  ##\\e[0m\\n"
	printf "\\e[1m##        https://github.com/jackyaz/uiScribe       ##\\e[0m\\n"
	printf "\\e[1m##                                                  ##\\e[0m\\n"
	printf "\\e[1m######################################################\\e[0m\\n"
	printf "\\n"
}

MainMenu(){
	Create_Dirs
	Create_Symlinks
	printf "1.    Customise list of logs displayed by %s\\n\\n" "$SCRIPT_NAME"
	printf "rf.   Clear user preferences for displayed logs\\n\\n"
	printf "u.    Check for updates\\n"
	printf "uf.   Update %s with latest version (force update)\\n\\n" "$SCRIPT_NAME"
	printf "e.    Exit %s\\n\\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\\n" "$SCRIPT_NAME"
	printf "\\n"
	printf "\\e[1m######################################################\\e[0m\\n"
	printf "\\n"
	
	while true; do
		printf "Choose an option:    "
		read -r menu
		case "$menu" in
			1)
				if Check_Lock menu; then
					Menu_CustomiseLogList
				fi
				PressEnter
				break
			;;
			rf)
				if Check_Lock menu; then
					Menu_ProcessUIScripts force
				fi
				PressEnter
				break
			;;
			u)
				printf "\\n"
				if Check_Lock menu; then
					Menu_Update
				fi
				PressEnter
				break
			;;
			uf)
				printf "\\n"
				if Check_Lock menu; then
					Menu_ForceUpdate
				fi
				PressEnter
				break
			;;
			e)
				ScriptHeader
				printf "\\n\\e[1mThanks for using %s!\\e[0m\\n\\n\\n" "$SCRIPT_NAME"
				exit 0
			;;
			z)
				while true; do
					printf "\\n\\e[1mAre you sure you want to uninstall %s? (y/n)\\e[0m\\n" "$SCRIPT_NAME"
					read -r confirm
					case "$confirm" in
						y|Y)
							Menu_Uninstall
							exit 0
						;;
						*)
							break
						;;
					esac
				done
				break
			;;
			*)
				printf "\\nPlease choose a valid option\\n\\n"
			;;
		esac
	done
	
	ScriptHeader
	MainMenu
}

Check_Requirements(){
	CHECKSFAILED="false"
	
	if [ "$(nvram get jffs2_scripts)" -ne 1 ]; then
		nvram set jffs2_scripts=1
		nvram commit
		Print_Output true "Custom JFFS Scripts enabled" "$WARN"
	fi
	
	if [ ! -f /opt/bin/opkg ]; then
		Print_Output true "Entware not detected!" "$ERR"
		CHECKSFAILED="true"
	fi
	
	if [ ! -f /opt/bin/scribe ]; then
		Print_Output true "Scribe not installed!" "$ERR"
		CHECKSFAILED="true"
	fi
	
	if [ "$CHECKSFAILED" = "false" ]; then
		return 0
	else
		return 1
	fi
}

Menu_Install(){
	Print_Output true "Welcome to $SCRIPT_NAME $SCRIPT_VERSION, a script by JackYaz"
	sleep 1
	
	Print_Output true "Checking your router meets the requirements for $SCRIPT_NAME"
	
	if ! Check_Requirements; then
		Print_Output true "Requirements for $SCRIPT_NAME not met, please see above for the reason(s)" "$CRIT"
		PressEnter
		Clear_Lock
		rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
		exit 1
	fi
	
	Create_Dirs
	Set_Version_Custom_Settings local
	Create_Symlinks
	Update_File Main_LogStatus_Content.asp
	Update_File shared-jy.tar.gz
	Auto_Startup create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_script create
	
	Print_Output true "uiScribe installed successfully!" "$PASS"
	
	Clear_Lock
}

Menu_CustomiseLogList(){
	Generate_Log_List
	printf "\\n"
	Clear_Lock
}

Menu_ProcessUIScripts(){
	Create_Symlinks "$1"
	printf "\\n"
	Clear_Lock
}

Menu_Startup(){
	if [ -z "$PPID" ] || ! ps | grep "$PPID" | grep -iq "scribe"; then
		if [ -z "$1" ]; then
			Print_Output true "Missing argument for startup, not starting $SCRIPT_NAME" "$WARN"
			exit 1
		elif [ "$1" != "force" ]; then
			if [ ! -f "$1/entware/bin/opkg" ]; then
				Print_Output true "$1 does not contain Entware, not starting $SCRIPT_NAME" "$WARN"
				exit 1
			else
				Print_Output true "$1 contains Entware, starting $SCRIPT_NAME" "$WARN"
			fi
		fi
	fi
	
	NTP_Ready
	
	Check_Lock
	
	Create_Dirs
	Set_Version_Custom_Settings local
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_script create
	Mount_WebUI
	Clear_Lock
}

Menu_Update(){
	Update_Version
	Clear_Lock
}

Menu_ForceUpdate(){
	Update_Version force
	Clear_Lock
}

Menu_Uninstall(){
	Print_Output true "Removing $SCRIPT_NAME..." "$PASS"
	Auto_Startup delete 2>/dev/null
	Auto_ServiceEvent delete 2>/dev/null
	Shortcut_script delete
	umount /www/Main_LogStatus_Content.asp 2>/dev/null
	rm -rf "$SCRIPT_DIR" 2>/dev/null
	rm -rf "$SCRIPT_WEB_DIR" 2>/dev/null
	rm -f "/jffs/scripts/$SCRIPT_NAME" 2>/dev/null
	Clear_Lock
	Print_Output true "Uninstall completed" "$PASS"
}

NTP_Ready(){
	if [ "$(nvram get ntp_ready)" -eq 0 ]; then
		ntpwaitcount="0"
		Check_Lock
		while [ "$(nvram get ntp_ready)" -eq 0 ] && [ "$ntpwaitcount" -lt 300 ]; do
			ntpwaitcount="$((ntpwaitcount + 1))"
			if [ "$ntpwaitcount" -eq 60 ]; then
				Print_Output true "Waiting for NTP to sync..." "$WARN"
			fi
			sleep 1
		done
		if [ "$ntpwaitcount" -ge 300 ]; then
			Print_Output true "NTP failed to sync after 5 minutes. Please resolve!" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output true "NTP synced, $SCRIPT_NAME will now continue" "$PASS"
			Clear_Lock
		fi
	fi
}

### function based on @Adamm00's Skynet USB wait function ###
Entware_Ready(){
	if [ ! -f /opt/bin/opkg ]; then
		Check_Lock
		sleepcount=1
		while [ ! -f "/opt/bin/opkg" ] && [ "$sleepcount" -le 10 ]; do
			Print_Output true "Entware not found, sleeping for 10s (attempt $sleepcount of 10)" "$ERR"
			sleepcount="$((sleepcount + 1))"
			sleep 10
		done
		if [ ! -f /opt/bin/opkg ]; then
			Print_Output true "Entware not found and is required for $SCRIPT_NAME to run, please resolve" "$CRIT"
			Clear_Lock
			exit 1
		else
			Print_Output true "Entware found, $SCRIPT_NAME will now continue" "$PASS"
			Clear_Lock
		fi
	fi
}
### ###

if [ -z "$1" ]; then
	NTP_Ready
	Entware_Ready
	sed -i '/\/dev\/null/d' "$SCRIPT_DIR/.logs_user"
	Create_Dirs
	Set_Version_Custom_Settings local
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_script create
	ScriptHeader
	MainMenu
	exit 0
fi

case "$1" in
	install)
		Check_Lock
		Menu_Install
		exit 0
	;;
	startup)
		Menu_Startup "$2"
		exit 0
	;;
	service_event)
		if [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}config" ]; then
			Logs_FromSettings
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}checkupdate" ]; then
			Update_Check
			exit 0
		elif [ "$2" = "start" ] && [ "$3" = "${SCRIPT_NAME}doupdate" ]; then
			Update_Version force unattended
			exit 0
		fi
		exit 0
	;;
	update)
		Update_Version unattended
		exit 0
	;;
	forceupdate)
		Update_Version force unattended
		exit 0
	;;
	setversion)
		Set_Version_Custom_Settings local
		Set_Version_Custom_Settings server "$SCRIPT_VERSION"
		if [ -z "$2" ]; then
			exec "$0"
		fi
		exit 0
	;;
	checkupdate)
		Update_Check
		exit 0
	;;
	develop)
		sed -i 's/^readonly SCRIPT_BRANCH.*$/readonly SCRIPT_BRANCH="develop"/' "/jffs/scripts/$SCRIPT_NAME"
		Update_Version force
		exit 0
	;;
	stable)
		sed -i 's/^readonly SCRIPT_BRANCH.*$/readonly SCRIPT_BRANCH="master"/' "/jffs/scripts/$SCRIPT_NAME"
		Update_Version force
		exit 0
	;;
	uninstall)
		Check_Lock
		Menu_Uninstall
		exit 0
	;;
	*)
		echo "Command not recognised, please try again"
		exit 1
	;;
esac
