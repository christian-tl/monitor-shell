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
INTERVAL=$[INTERVAL*60]
COUNT=${COUNT:=1}

PECENT=${PECENT:=80}

shift $(($OPTIND - 1))

checkDisk(){
  check_date=`date "+%Y-%m-%d_%H-%M"`
  check_log="$LOG_PATH/disk_alarming_$check_date.txt"
  rm -f $check_log
 
  printf " ${blue}%-8s %-16s %-20s %-6s${reset}\n" "ITEM" "HOST_IP" "Mounted_On" "Use%"
  for CUR_HOST in `cat $CONF_FILE | egrep -v ^# |egrep -v ^$`
  do
    diskInfo=`ssh -fnq -l root $CUR_HOST "df |grep -v Use"`
    max_pcent=0
    max_pcent_path=""
    diskInfo=($diskInfo)
    k=0;
    for info in ${diskInfo[@]}
    do
        pcent=`echo ${diskInfo[${k+4}]} | cut -d% -f1`
        cpath=${diskInfo[$[k+5]]}
        if ((max_pcent < pcent));then
            max_pcent=$pcent
            max_pcent_path=$cpath
        fi
        k=$[k+6]
    done
    if ((max_pcent > $PECENT));then
       printf "${red} %-8s %-16s %-20s %-6s${reset}\n" "Disk"  $CUR_HOST $max_pcent_path ${max_pcent}%
       echo -e $CUR_HOST\\t $max_pcent_path\\t ${max_pcent}%\\t\\n >> $check_log
    else
       printf " %-8s %-16s %-20s %-6s\n" "Disk" $CUR_HOST $max_pcent_path ${max_pcent}%
    fi
  done
 
  if [ -f ${check_log} ]; then
     curl -s -o /dev/null -i -H "Content-Type: application/text" --connect-timeout 2 -X POST -d @${check_log} "${MAIL_SERVICE_URL}Disk_Space_Usage_over%20${PECENT}%20Percent!"
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

