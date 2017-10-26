#!/bin/bash

source ./setenv.sh

helpInfo(){
    echo "Usage: `basename $0` [options] [ <interval> [ <count> ] ]"
    echo "options are:"
    echo "    -h : host ip file"
    echo "    -p : disk used pencent"
}

if [[ $# < 2 ]];then
   helpInfo;
   exit 1	
fi

while getopts 'h:p:' OPT; do
    case $OPT in
      h)
          CONF_FILE="$OPTARG";;
      p)
          PECENT="$OPTARG";;
      ?)
          helpInfo 
      exit 1
    esac
done

if [[ -z "${PECENT}" ]];then
  INTERVAL=$3
  COUNT=$4
else
  INTERVAL=$5
  COUNT=$6
fi
INTERVAL=${INTERVAL:=1}
COUNT=${COUNT:=1}
PECENT=${PECENT:=80}

checkMem(){
  check_date=`date "+%Y-%m-%d_%H-%M"`
  check_log="$LOG_PATH/mem_alarming_$check_date.txt"
  rm -f $check_log

  printf " ${blue}%-12s %-16s %-8s %-8s %-8s %-8s %-8s %-8s %-10s %-8s${reset}\n" "ITEM" "HOST_IP"  "TOTAL" "USED" "FREE" "SHARED" "BUFFERS" "CACHED" "AVAILABLE" "%USED"
  for CUR_HOST in `cat $CONF_FILE | egrep -v ^# |egrep -v ^$`
  do
    memInfo=`ssh -f -n -q -l root $CUR_HOST "free | grep Mem"`
    mems=(${memInfo})
    total=$[${mems[1]}/1024]
    used=$[${mems[2]}/1024]
    free=$[${mems[3]}/1024]
    shared=$[${mems[4]}/1024]
    buffers=$[${mems[5]}/1024]
    cached=$[${mems[6]}/1024]
    available=$[$free+$buffers+$cached]
    pcent=$[100-$available*100/$total] 
    if (($pcent > $PECENT));then
      printf "${red} %-12s %-16s %-8s %-8s %-8s %-8s %-8s %-8s %-10s %-8s${reset}\n" "Memory(M)" $CUR_HOST $total $used $free $shared $buffers $cached $available $pcent%
      echo -e $CUR_HOST\\t Memory Usage: ${pcent}% \\t\\n >> $check_log
    else
      printf " %-12s %-16s %-8s %-8s %-8s %-8s %-8s %-8s %-10s %-8s\n" "Memory(M)" $CUR_HOST $total $used $free $shared $buffers $cached $available $pcent% 
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

