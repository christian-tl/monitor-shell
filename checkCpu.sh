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

PECENT=${PECENT:=40}

shift $(($OPTIND - 1))

checkDisk(){
  check_date=`date "+%Y-%m-%d_%H-%M"`
  check_log="$LOG_PATH/cpu_alarming_$check_date.txt"
  rm -f $check_log

  printf " ${blue}%-16s %-6s %-6s %-6s %-8s %-8s %-8s %-8s %-8s ${reset}\n"  "HOST_IP"  "%US" "%SY" "%NI" "%IDLE" "%IOWAIT" "M1_LOAD" "M10_LOAD" "M15_LOAD" 
  for CUR_HOST in `cat $CONF_FILE | egrep -v ^# |egrep -v ^$`
  do
    cpuInfo=`ssh -f -n -q -l root $CUR_HOST "top -b -d 0.2 -n 2 | grep -i Cpu\(s\) | tail -n 1"`
    used=0
    cpuUse=($cpuInfo)
    us=`echo ${cpuUse[1]} | cut -d% -f1`
    sy=`echo ${cpuUse[2]} | cut -d% -f1`
    ni=`echo ${cpuUse[3]} | cut -d% -f1`
    idle=`echo ${cpuUse[4]} | cut -d% -f1`
    iowait=`echo ${cpuUse[5]} | cut -d% -f1`
    idle2=`echo $idle | cut -d. -f1`
    used=$[100-$idle2]
    load=`ssh -fnq -l root $CUR_HOST "uptime"`
    load3=`echo $load | awk '{print $10,$11,$12}' | awk -F"[,]" '{print $1 $2 $3}'`
    if (($used > $PECENT));then
      printf "${red} %-16s %-6s %-6s %-6s %-8s %-8s %-8s %-8s %-8s${reset}\n" "*$CUR_HOST" $us $sy $ni $idle $iowait ${load3[0]} ${load3[1]} ${load3[2]}
      echo -e $CUR_HOST\\t CPU Use ${used}% \\t\\n >> $check_log
    else
      printf " %-16s %-6s %-6s %-6s %-8s %-8s %-8s %-8s %-8s\n" $CUR_HOST $us $sy $ni $idle $iowait ${load3[0]} ${load3[1]} ${load3[2]}
    fi
  done
 
  if [ -f ${check_log} ]; then
     curl -s -o /dev/null -i -H "Content-Type: application/text" --connect-timeout 2 -X POST -d @${check_log} ${MAIL_SERVICE_URL}CPU%20Usage%20over%20${PECENT}%20Percent!
  fi
}

i=0
while [ $i -lt $COUNT -o $COUNT -eq 0 ]
do
  checkDisk
  if [[ $COUNT != 0 ]]; then
    let i++
  fi
  echo " " 
  if [[ $COUNT > 1 ]]; then
    sleep $INTERVAL
  fi
done

