#!/bin/bash

HOSTNAME=`hostname`
TS=`date +%s%N`
INFLUXDB=telegraf
INFLUXHOST_PORT=192.168.50.81:8086

TEMP=`/opt/vc/bin/vcgencmd measure_temp | sed "s/'//g" | sed "s/C//g" | sed "s/temp=//g"`

INFLUXDATA=`echo "temperature,HOSTNAME="${HOSTNAME}" CPU="${TEMP}" "${TS}`

# echo ${INFLUXDATA}
curl -XPOST http://${INFLUXHOST_PORT}/write?db=${INFLUXDB} --data-binary "${INFLUXDATA}"
