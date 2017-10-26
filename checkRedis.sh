#!/bin/bash

source ./setenv.sh

helpInfo(){
   echo "Usage: `basename $0` [options] [ <interval> [ <count> ] ]"
   echo "options are:"
   echo "    -h : host&port file"
}

while getopts 'h:' OPT; do
    case $OPT in
      h)
          REQ_HOSTS="$OPTARG";;
      ?)
          helpInfo
      exit 1
    esac
done

if [[ $# < 2 ]];then
   helpInfo;
   exit 1
fi

INTERVAL=$3
COUNT=$4
INTERVAL=${INTERVAL:=1}
COUNT=${COUNT:=1}

checkRedis(){
  red=`tput setaf 1`
  green=`tput setaf 2`
  reset=`tput sgr0`
  check_date=`date "+%Y-%m-%d_%H-%M"`
  check_log="$LOG_PATH/check_redis.txt"
  check_fail_log="$LOG_PATH/check_redis_fail_$check_date.txt"
  printf " ${blue}%-8s %-16s %-8s %-8s${reset}\n" "ITEM" "HOST_IP" "PORT" "STATUS" 
  cat $REQ_HOSTS | egrep -v ^# |egrep -v ^$ | while read INFO
  do
     info=(${INFO})
     CUR_HOST=${info[0]}
     i=1
     while [ $i -lt ${#info[@]} ]
     do
       REQ_PORT=${info[$i]}
       pong_count=`$REDIS_CLIENT_CMD -h $CUR_HOST -p $REQ_PORT -r 3 -i 0.1 ping |grep PONG |wc -l`
       if [[ $pong_count > 0 ]];then
         printf " %-8s %-16s %-8s %-8s\n" "Redis" $CUR_HOST $REQ_PORT "OK"
       else
         printf "${red} %-8s %-16s %-8s %-8s${reset}\n" "Redis" $CUR_HOST $REQ_PORT "Invalid"
         date_str=`date "+%Y-%m-%d %H:%M:%S"`
         error_info="$date_str $CUR_HOST:$REQ_PORT Redis Status: Invalid!"
         echo $error_info >> ${check_fail_log}
       fi
       let i++
    done
  done

  if [ -f ${check_fail_log} ]; then
     curl -s -o /dev/null -i -H "Content-Type: application/text" --connect-timeout 2 -X POST -d @${check_fail_log} ${MAIL_SERVICE_URL}Redis Service Invalid
     #mail -s "[MonitoringAlarm] Redis Service Invalid" -c $MAIL_TO < ${check_fail_log}    
     #rm -rf $check_fail_log
  fi
}

i=0
while [ $i -lt $COUNT -o $COUNT -eq 0 ]
do
  checkRedis
  if [[ $COUNT != 0 ]]; then
    let i++
  fi
  echo " "
  if [[ $COUNT > 1 ]]; then
    sleep $INTERVAL
  fi
done
