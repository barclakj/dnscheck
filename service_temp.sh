#!/bin/bash
SCRIPT_PATH=/home/pi/src/dnscheck
TS=`date +%s%N`
INFLUXDB=telegraf
INFLUXHOST_PORT=192.168.50.81:8086
HOSTNAME=`hostname`
RUNNING_COUNT=`ps -ef | grep temp-sensor.py | grep -v "grep" | wc -l`

function raiseAlert() {
    INFLUXDATA=`echo "TEMPALERT,HOSTNAME="${HOSTNAME}",MSG="$1" alert=1 "${TS}`
	curl -XPOST http://${INFLUXHOST_PORT}/write?db=${INFLUXDB} --data-binary "${INFLUXDATA}"
    echo ${INFLUXDATA}
}

function restartTemp() {
	nohup python3 /home/pi/src/temp-sensor.py > /dev/null &
}

if [ ${RUNNING_COUNT} == "0" ]
then
    echo "Failed to detect temp sensor running... Restarting process..."
    raiseAlert "RESTART_TEMP_SENSOR"
    restartTemp
else
    echo "Temp sensor appears to be running..."
fi

