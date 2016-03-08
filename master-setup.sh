#!/bin/bash
#Created by Victor Roos on 08.03.2016 15:00

##########################
#Install script for Sonarr
##########################

SONARR_INIT_F=/etc/init.d/nzbdrone
  #trhis section will add the repo and install the key for the sonarr repo
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FDA5DFFC
echo "deb https://apt.sonarr.tv/ master main" | sudo tee -a /etc/apt/sources.list.d/sonarr.list
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install nzbdrone -y
sudo chown pi:pi -R /opt/NzbDrone
  #This will verify if the file nzbdrone existsa in /etc/init.d/ folder and 
  #if NOT it will create it and paste the content of the EOF section
if [ ! -w $SONARR_INIT_F ]
  then  cat >$SONARR_INIT_F <<EOF
#! /bin/sh
### BEGIN INIT INFO
# Provides: NzbDrone
# Required-Start: $local_fs $network $remote_fs
# Required-Stop: $local_fs $network $remote_fs
# Should-Start: $NetworkManager
# Should-Stop: $NetworkManager
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: starts instance of NzbDrone
# Description: starts instance of NzbDrone using start-stop-daemon
### END INIT INFO

############### EDIT ME ##################
# path to app
APP_PATH=/opt/NzbDrone

# user
RUN_AS=pi

# path to mono bin
DAEMON=$(which mono)

# Path to store PID file
PID_FILE=/var/run/nzbdrone/nzbdrone.pid
PID_PATH=$(dirname $PID_FILE)

# script name
NAME=nzbdrone

# app name
DESC=NzbDrone

# startup args
EXENAME="NzbDrone.exe"
DAEMON_OPTS=" "$EXENAME

############### END EDIT ME ##################

NZBDRONE_PID=`ps auxf | grep NzbDrone.exe | grep -v grep | awk '{print $2}'`

test -x $DAEMON || exit 0

set -e

#Look for PID and create if doesn't exist
if [ ! -d $PID_PATH ]; then
mkdir -p $PID_PATH
chown $RUN_AS $PID_PATH
fi

if [ ! -d $DATA_DIR ]; then
mkdir -p $DATA_DIR
chown $RUN_AS $DATA_DIR
fi

if [ -e $PID_FILE ]; then
PID=`cat $PID_FILE`
if ! kill -0 $PID > /dev/null 2>&1; then
echo "Removing stale $PID_FILE"
rm $PID_FILE
fi
fi

echo $NZBDRONE_PID > $PID_FILE

case "$1" in
start)
if [ -z "${NZBDRONE_PID}" ]; then
echo "Starting $DESC"
rm -rf $PID_PATH || return 1
install -d --mode=0755 -o $RUN_AS $PID_PATH || return 1
start-stop-daemon -d $APP_PATH -c $RUN_AS --start --background --pidfile $PID_FILE --exec $DAEMON -- $DAEMON_OPTS
else
echo "NzbDrone already running."
fi
;;
stop)
echo "Stopping $DESC"
echo $NZBDRONE_PID > $PID_FILE
start-stop-daemon --stop --pidfile $PID_FILE --retry 15
;;

restart|force-reload)
echo "Restarting $DESC"
start-stop-daemon --stop --pidfile $PID_FILE --retry 15
start-stop-daemon -d $APP_PATH -c $RUN_AS --start --background --pidfile $PID_FILE --exec $DAEMON -- $DAEMON_OPTS
;;
status)
# Use LSB function library if it exists
if [ -f /lib/lsb/init-functions ]; then
. /lib/lsb/init-functions
if [ -e $PID_FILE ]; then
status_of_proc -p $PID_FILE "$DAEMON" "$NAME" && exit 0 || exit $?
else
log_daemon_msg "$NAME is not running"
exit 3
fi

else
# Use basic functions
if [ -e $PID_FILE ]; then
PID=`cat $PID_FILE`
if kill -0 $PID > /dev/null 2>&1; then
echo " * $NAME is running"
exit 0
fi
else
echo " * $NAME is not running"
exit 3
fi
fi
;;
*)
N=/etc/init.d/$NAME
echo "Usage: $N {start|stop|restart|force-reload|status}" >&2
exit 1
;;
esac

exit 0
EOF
else  echo "the file exists: $SONARR_INIT_F"
fi

sudo chmod +x /etc/init.d/nzbdrone
sudo update-rc.d nzbdrone defaults
echo "Sonarr/NzbDrone is installed on your Raspberry Pi"
exit 0
