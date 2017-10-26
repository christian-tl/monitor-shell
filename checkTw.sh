#!/bin/bash

source ./setenv.sh

helpInfo(){
   echo "Usage: `basename $0` [options] [ <interval> [ <count> ] ]"
   echo "options are:"
   echo "    -h : tw host file"
   echo "    -p : tw port"
}

while getopts 'h:p:' OPT; do
    case $OPT in
      h)
          REQ_HOSTS="$OPTARG";;
      p) 
          REQ_PORT="$OPTARG";;
      ?)
          helpInfo
      exit 1
    esac
done

if [[ $# < 4 ]];then
   helpInfo;
   exit 1
fi

INTERVAL=$5
COUNT=$6
INTERVAL=${INTERVAL:=1}
COUNT=${COUNT:=1}

checkTw(){
  red=`tput setaf 1`
  green=`tput setaf 2`
  reset=`tput sgr0`
  check_date=`date "+%Y-%m-%d_%H-%M"`
  check_fail_log="$LOG_PATH/check_tw_fail_$check_date.txt"
  printf " ${blue}%-8s %-16s %-8s %-8s${reset}\n" "ITEM" "HOST_IP" "PORT" "STATUS"
  for CUR_HOST in $(cat ${REQ_HOSTS} | egrep -v ^# |egrep -v ^$)
  do
     pong_count=`$REDIS_CLIENT_CMD -h $CUR_HOST -p $REQ_PORT -r 3 -i 0.1 ping |grep PONG |wc -l`
     if [[ $pong_count > 0 ]];then
       printf " %-8s %-16s %-8s %-8s\n" "Tw" $CUR_HOST $REQ_PORT "OK"
     else
       printf "${red} %-8s %-16s %-8s %-8s${reset}\n" "Tw" $CUR_HOST $REQ_PORT "Invalid"
       date_str=`date "+%Y-%m-%d %H:%M:%S"`
       error_info="$date_str $CUR_HOST:$REQ_PORT Tw Status: Invalid!"
       echo $error_info >> ${check_fail_log}
     fi
  done

  if [ -f ${check_fail_log} ]; then
     curl -s -o /dev/null -i -H "Content-Type: application/text" --connect-timeout 2 -X POST -d @${check_fail_log} ${MAIL_SERVICE_URL}Tw Service Invalid
     #mail -s "[MonitoringAlarm] Tw Service Invalid" -c $MAIL_TO < ${check_fail_log}    
     #rm -rf $check_fail_log
  fi
}

i=0
while [ $i -lt $COUNT -o $COUNT -eq 0 ]
do
  checkTw
  if [[ $COUNT != 0 ]]; then
    let i++
  fi
  echo " "
  sleep $INTERVAL
done
