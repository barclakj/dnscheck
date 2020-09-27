#!/bin/bash

LOGFILE=/tmp/checkdnsoutput.log
DNSSERVER=${1}
DNSPORT=${2}
TARGETSERVER=google.com
HOSTNAME=`hostname`
TS=`date +%s%N`
INFLUXDB=telegraf
INFLUXHOST_PORT=192.168.50.81:8086
SEND_TO_INFLUX=${3}
QUERYTIME="1000"

dig @${DNSSERVER} ${TARGETSERVER} -p ${DNSPORT} A +retry=1 +timeout=1 > ${LOGFILE}

STATUS=`cat ${LOGFILE} | grep "status: NOERROR" | wc -l`

if [ ${STATUS} == "1" ]
then
	echo "DNS SERVER "${DNSSERVER}":"${DNSPORT}" IS UP!"
else
	echo "DNS SERVER "${DNSSERVER}":"${DNSPORT}" IS DOWN!"
fi

if [ ${STATUS} == "1" ]
then
	QUERYTIME=`cat ${LOGFILE} | grep "Query time" | awk -F' ' '{print $4}'`
fi

INFLUXDATA=`echo "DNSSTATUS,HOSTNAME="${HOSTNAME}",DNSPORT="${DNSPORT}",DNSSERVER="${DNSSERVER}",TARGETSERVER="${TARGETSERVER}" status="${STATUS}",querytime="${QUERYTIME}" "${TS}`

if [[ ${SEND_TO_INFLUX} == "-export" ]]
then
	curl -XPOST http://${INFLUXHOST_PORT}/write?db=${INFLUXDB} --data-binary "${INFLUXDATA}"
fi 

