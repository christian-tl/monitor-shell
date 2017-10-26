#!/bin/bash

source ./setenv.sh

helpInfo(){
    echo "Usage: `basename $0` [options] [ <interval> [ <count> ] ]"
    echo "options are:"
    echo "    -h : host ip file"
  echo "    -e : eth name"
    echo "    -m : max throughput,Mb"
}

if [[ $# < 4 ]];then
   helpInfo;
   exit 1 
fi

while getopts 'h:e:m:' OPT; do
    case $OPT in
      h)
          CONF_FILE="$OPTARG";;
    e)
          ETH="$OPTARG";;
      m)
          MAX="$OPTARG";;
      ?)
          helpInfo 
      exit 1
    esac
done

if [[ -z "${MAX}" ]];then
  INTERVAL=$5
  COUNT=$6
else
  INTERVAL=$7
  COUNT=$8
fi
INTERVAL=${INTERVAL:=1}
COUNT=${COUNT:=1}
MAX=${MAX:=80}

checkMem(){
  check_date=`date "+%Y-%m-%d_%H-%M"`
  check_log="$LOG_PATH/netio_alarming_$check_date.txt"
  rm -f $check_log

  printf " ${blue}%-12s %-16s %-10s %-10s ${reset}\n" "ITEM" "HOST_IP"  "TX" "RX"  
  PREFIX="/sys/class/net/$ETH/statistics"
  for CUR_HOST in `cat $CONF_FILE | egrep -v ^# |egrep -v ^$`
  do
    ioInfo=`ssh -f -n -q -l root $CUR_HOST "cat ${PREFIX}/rx_bytes && cat ${PREFIX}/tx_bytes && sleep 1 && cat ${PREFIX}/rx_bytes && cat ${PREFIX}/tx_bytes"`
    ios=(${ioInfo})
    rx1=`echo "scale=3;${ios[0]}/1024" | bc`
    tx1=`echo "scale=3;${ios[1]}/1024" | bc`
    rx2=`echo "scale=3;${ios[2]}/1024" | bc`
    tx2=`echo "scale=3;${ios[3]}/1024" | bc`
    rx=`echo "scale=3;($rx2 - $rx1)/1024" |bc`
    tx=`echo "scale=3;($tx2 - $tx1)/1024" |bc`
    alarm1=`echo "scale=3;$rx > $MAX" |bc`
    alarm2=`echo "scale=3;$tx > $MAX" |bc`
    if (($alarm1 > 0 || $alarm2 > 0));then
      printf "${red} %-12s %-16s %-10s %-10s${reset}\n" "NetIO(M)" "*$CUR_HOST" $rx $tx
      echo -e $CUR_HOST\\t NetIO : RX=${rx}Mb \\t TX=${tx}Mb \\n >> $check_log
    else
      printf " %-12s %-16s %-10s %-10s\n" "NetIO(M)" $CUR_HOST $rx $tx
    fi
  done
 
  if [ -f ${check_log} ]; then
     curl -s -o /dev/null -i -H "Content-Type: application/text" --connect-timeout 2 -X POST -d @${check_log} ${MAIL_SERVICE_URL}Memory%20Usage%20is%20Over%20${PECENT}%20Percent!
  fi
}

i=0
while [ $i -lt $COUNT -o $COUNT -eq 0 ]
do
  checkMem
  if [[ $COUNT != 0 ]]; then
    let i++
  fi
  echo " " 
  if [[ $COUNT > 1 ]]; then
    sleep $INTERVAL
  fi
done


