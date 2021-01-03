#!/bin/bash
SCRIPT_PATH=/home/pi/src/dnscheck
TS=`date +%s%N`
INFLUXDB=telegraf
INFLUXHOST_PORT=192.168.50.81:8086
HOSTNAME=`hostname`
RUNNING_COUNT=`ps -ef | grep twitterlisten.py | grep -v "grep" | wc -l`

function raiseAlert() {
    INFLUXDATA=`echo "LIGHTSALERT,HOSTNAME="${HOSTNAME}",MSG="$1" alert=1 "${TS}`
	curl -XPOST http://${INFLUXHOST_PORT}/write?db=${INFLUXDB} --data-binary "${INFLUXDATA}"
    echo ${INFLUXDATA}
}

function restartLightSwitcher() {
	nohup python3 /home/pi/src/xmasr2/twitterlisten.py COLOUR > /dev/null &
}

if [ ${RUNNING_COUNT} == "0" ]
then
    echo "Failed to detect light switcher running... Restarting process..."
    raiseAlert "RESTART_LIGHT_SWITCHER"
    restartLightSwitcher
else
    echo "Light switcher sensor appears to be running..."
fi

