#!/bin/bash

source ./setenv.sh

helpInfo(){
    echo "Usage: `basename $0` [options] [ <interval> [ <count> ] ]"
    echo "options are:"
    echo "    -h : host ip file"
}

if [[ $# < 2 ]];then
   helpInfo;
   exit 1	
fi

while getopts 'h:' OPT; do
    case $OPT in
      h)
          CONF_FILE="$OPTARG";;
      ?)
          helpInfo 
      exit 1
    esac
done

INTERVAL=$3
COUNT=$4
INTERVAL=${INTERVAL:=1}
COUNT=${COUNT:=1}

checkConnection(){
  check_date=`date "+%Y-%m-%d_%H-%M"`
  check_log="$LOG_PATH/connection_alarming_$check_date.txt"
  rm -f $check_log

  printf " ${blue}%-15s %-16s %-12s %-12s %-12s %-12s \n${reset}" "ITEM" "HOST_IP"  "ESTABLISHED" "TIME_WAIT" "FIN_WAIT" "LISTEN" 
  cat $CONF_FILE | egrep -v ^# |egrep -v ^$ | while read line
  do
    confInfo=($line)
    CUR_HOST=${confInfo[0]}
    MAX_ECON=${confInfo[1]}
    MAX_WCON=${confInfo[2]}
    connections=`ssh -fnq -l root $CUR_HOST "netstat -anp |grep ESTABLISHED |wc -l && netstat -anp |grep TIME_WAIT |wc -l && netstat -anp |grep FIN_WAIT1 |wc -l && netstat -anp |grep LISTEN |wc -l"`
    cons=($connections)
    if ((${cons[0]} > $MAX_ECON));then
      printf "${red} %-15s %-16s %-12s %-12s %-12s %-12s${reset}\n" "Connections" $CUR_HOST ${cons[0]} ${cons[1]} ${cons[2]} ${cons[3]}
      echo -e $CUR_HOST\\t Established Connections: ${cons[0]}, Wait Connections: ${cons[1]} \\t\\n >> $check_log
    else
      printf " %-15s %-16s %-12s %-12s %-12s %-12s\n" "Connections" $CUR_HOST ${cons[0]} ${cons[1]} ${cons[2]} ${cons[3]}
    fi
  done
 
  if [ -f ${check_log} ]; then
     curl -s -o /dev/null -i -H "Content-Type: application/text" --connect-timeout 2 -X POST -d @${check_log} ${MAIL_SERVICE_URL}ESTABLISHED%20Connections:%20${cons[0]}!
  fi
}

i=0
while [ $i -lt $COUNT -o $COUNT -eq 0 ]
do
  checkConnection
  if [[ $COUNT != 0 ]]; then
    let i++
  fi
  echo " " 
  if [[ $COUNT > 1 ]]; then
    sleep $INTERVAL
  fi
done

