#!/bin/bash

SCRIPT_PATH=/home/pi/src/dnscheck
TS=`date +%s%N`
INFLUXDB=telegraf
INFLUXHOST_PORT=192.168.50.81:8086
HOSTNAME=`hostname`

function restartPiHole() {
    sudo systemctl stop pihole-FTL
    sudo systemctl stop privoxy
    sudo systemctl stop lighttpd
    sudo systemctl stop cloudflared

    sleep 4

    sudo systemctl start cloudflared
    sudo systemctl start lighttpd
    sudo systemctl start privoxy
    sudo systemctl start pihole-FTL

    sleep 4

    pihole restartdns

    sleep 4

    pihole status
}

# Let's check the temperature whilst we're at it..
${SCRIPT_PATH}/check_temp.sh

STATUS=`${SCRIPT_PATH}/checkdns.sh 127.0.0.1 53 -noexport | grep "IS DOWN!" | wc -l`

if [ ${STATUS} == "1" ]
then
    echo "Failed to resolve... Restarting P-iHole."
    restartPiHole
fi

STATUS=`${SCRIPT_PATH}/checkdns.sh 127.0.0.1 53 -noexport | grep "IS DOWN!" | wc -l`

if [ ${STATUS} == "1" ]
then
    echo "Failed to resolve for the 2nd time..."
    INFLUXDATA=`echo "DNS,HOSTNAME="${HOSTNAME}" status=0 "${TS}`
	curl -XPOST http://${INFLUXHOST_PORT}/write?db=${INFLUXDB} --data-binary "${INFLUXDATA}"

    if test -f "${SCRIPT_PATH}/RESTART"
    then
        echo "Rebooted once already... not retrying"
    else
        echo "RESTARTED" > ${SCRIPT_PATH}/RESTART
        echo "Rebooting..."
        sleep 10
        sudo reboot now
    fi
else
    if test -f "${SCRIPT_PATH}/RESTART"
    then
        rm ${SCRIPT_PATH}/RESTART
    fi
    INFLUXDATA=`echo "DNS,HOSTNAME="${HOSTNAME}" status=1 "${TS}`
	curl -XPOST http://${INFLUXHOST_PORT}/write?db=${INFLUXDB} --data-binary "${INFLUXDATA}"
fi
