#!/bin/bash
######################################
### Created by Victor Roos 
### First commit: 09.03.2016 12:00
### Latest commit: 06.05.2016 10:00
### v. 0.2.4.0
######################################

### Checking if the script is run as root

if [[ $EUID != 0 ]]
	then
		echo Please run the script as root or with sudo
		exit
	else
		echo Running the script as root 2>&1 >> setup.log
fi

sys_update() {
	echo Updating the system: $HOSTNAME ...
	apt-get update 2>&1 >> setup.log
	echo Upgrading the system: $HOSTNAME ...
	apt-get upgrade -y --force-yes 2>&1 >> setup.log
	echo $HOSTNAME is up to date.
	return 0
}

### Install script for Sonarr

sonarr() {
	SONARR_INIT_F=/etc/systemd/system/sonarr.service
	SONARR_REPO_F=/etc/apt/sources.list.d/sonarr.list
	MONO_VER=$(mono -V | grep version | awk '{print $5}')
	echo Installing Sonarr on $HOSTNAME ... please wait
    #this section will add the repo and install the key for the sonarr repo
	if [ ! -f $SONARR_REPO_F ]
		then
			echo Installing key ...
            apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FDA5DFFC 2>&1 >> setup.log
            echo Creating $SONARR_REPO_F file
            echo "deb https://apt.sonarr.tv/ master main" | tee -a /etc/apt/sources.list.d/sonarr.list
		else
			echo The .list file already exists: $SONARR_REPO_F 2>&1 >> setup.log
	fi
	echo Updating the system: $HOSTNAME ...
	apt-get update 2>&1 >> setup.log
	apt-get upgrade -y 2>&1 >> setup.log
	if [ $(which mono) != "/usr/bin/mono" ]
		then
			echo Installing MONO runtime ...
			apt-get install mono-complete -y 2>&1 >> setup.log
		else
			echo Mono $MONO_VER is installed ...
	fi
	if [ $(find /opt/ -name NzbDrone.exe) != "/opt/NzbDrone/NzbDrone.exe" ]
		then
			echo Installing Sonarr package ...
			apt-get install nzbdrone -y 2>&1 >> setup.log
		else
			echo Sonarr is already installed ... nothing to do here ...
			sleep 1
			echo Bye!
			return 0
	fi
	chown pi:pi -R /opt/NzbDrone
### This will verify if the file Sonarr existsa in /etc/init.d/ folder and 
### if NOT it will create it and paste the content of the EOF section
	if [ ! -w $SONARR_INIT_F ]
		then cat >$SONARR_INIT_F <<EOF
[Unit]
Description=Sonarr Daemon
After=network.target

[Service]
User=pi
Group=pi
Type=simple
ExecStart=/usr/bin/mono --debug /opt/NzbDrone/NzbDrone.exe

[Install]
WantedBy=multi-user.target
EOF
		else
			echo The file $SONARR_INIT_F exists
	fi
	systemctl enable nzbdrone.service
	systemctl start nzbdrone.service
	echo Sonarr is installed on $HOSTNAME
	return 0
}
couchpotato(){
	CP_SERVICE_F=/etc/systemd/system/couchpotato.service
	# echo This option is not yet implemented ... please try another number
	#sleep 5
	echo Installing dependencies | tee -a setup.log
	apt-get install git-core libffi-dev libssl-dev zlib1g-dev libxslt1-dev libxml2-dev python python-pip python-dev build-essential -y --force-yes 2>&1 >> setup.log
	echo Installing couchpotato from github  | tee -a setup.log
	git clone https://github.com/CouchPotato/CouchPotatoServer /opt/couchpotato
	chown -R pi:pi /opt/couchpotato
	if [ == $CP_SERVICE_F ]
		then
			echo The service is installed
		else
			cat >>$CP_SERVICE_F <<EOF
[Unit]
Description=CouchPotato Daemon
After=network.target

[Service]
User=pi
Group=pi
Type=simple
ExecStart=/usr/bin/python /opt/couchpotato/CouchPotato.py

[Install]
WantedBy=multi-user.target
EOF
	fi
	systemctl enable couchpotato.service
	systemctl start couchpotato.service
	return 0
}

jackett(){
	# Variables
	JACKETT_D=/opt/Jackett
	JACKETT_TMP_D=/opt/kitt
	JACKETT_TMP_HTM_F=/opt/kitt/jackett.tmp
	mkdir -p $JACKETT_TMP_D 
	# Downloading releases html file to be parsed
	wget -O $JACKETT_TMP_HTM_F https://github.com/Jackett/Jackett/releases |& tail >> setup.log
	# Parsing release file to look for a direct download link
	JACKETT_LNK=`cat $JACKETT_TMP_HTM_F | grep -m 1 -o -E "/Jackett/Jackett/releases/download/[^<>]*?/Jackett.Binaries.Mono.tar.gz"`
	# Parsing for version
	JACKETT_VER=`cat $JACKETT_TMP_HTM_F | grep -m 1 "css-truncate-target" | grep -E -o "v[^<>]*?" | head -1`
	JACKETT_TMP_F=/opt/kitt/Jackett-$JACKETT_VER.tar.gz
	JACKETT_TMP_F_VER=`ls /opt/kitt/ | grep -o -P '(?<=Jackett-).*(?=.tar.gz)' | tail -1`
	JACKETT_DL=https://github.com$JACKETT_LNK
	if [ "$JACKETT_TMP_F_VER" == "$JACKETT_VER" ]
		then
			echo You have the latest version installed | tee -a setup.log
			echo Server version $JACKETT_VER | tee -a setup.log
			echo Local Version $JACKETT_TMP_F_VER | tee -a setup.log
		else
			echo Updating Jackett to the latest version | tee -a setup.log
			sleep 1
			echo Removing old downloaded file | tee -a setup.log
			rm -rf /opt/kitt/Jackett-$JACKETT_TMP_F_VER.tar.gz 2>&1 >> setup.log
			echo Downloading the new file from server | tee -a setup.log
			wget -nc -O $JACKETT_TMP_F $JACKETT_DL |& tail >> setup.log
			echo Stopping jackett.service | tee -a setup.log
			systemctl stop jackett.service
			sleep 2
			echo Removing Jackett directory content | tee -a setup.log
			rm -vrf $JACKETT_D/* 2>&1 >> setup.log
			echo Unpacking the new version | tee -a setup.log
			tar -xvf $JACKETT_TMP_F -C /opt 2>&1 >> setup.log
			echo Starting jackett.service | tee -a setup.log
			systemctl start jackett.service
	fi
	echo Removing temp files | tee -a setup.log
	rm -f $JACKETT_TMP_HTM_F 2>&1 >> setup.log
	return 0
}

webmin(){
	echo This option is not yet implemented ... please try another number
	sleep 5
	return 0
}

plex()  {
	echo This option is not yet implemented ... please try another option
	sleep 5
	return 0
        }

all()   {
        echo This option is not yet implemented ... please try another option
        sleep 5
        # sonarr
        # couchpotato
        # jackett
        # plex
        # webmin
        return 0
        }

quit()  {
	echo Quiting the script ... bye bye!
	sleep 1
	exit 0
}

error() {
	echo bad option ... try again
}

OPTIONS="SYS-Update Sonarr CouchPotato Jackett Webmin Plex All Quit"
select opt in $OPTIONS; do
	if [ "$opt" = "SYS-Update" ]; then
			sys_update
		elif [ "$opt" = "Sonarr" ]; then
			sonarr
		elif [ "$opt" = "CouchPotato" ]; then
			couchpotato
		elif [ "$opt" = "Jackett" ]; then
			jackett
		elif [ "$opt" = "Webmin" ]; then
			webmin
		elif [ "$opt" = "Plex" ]; then
			plex
		elif [ "$opt" = "All" ]; then
			all
		elif [ "$opt" = "Quit" ]; then
			quit
		else
			error
	fi
done
