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

checkGC(){
  check_date=`date "+%Y-%m-%d_%H-%M"`
  check_log="$LOG_PATH/gc_$check_date.txt"
  rm -f $check_log

  printf " ${blue}%-8s %-16s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s${reset}\n" "ITEM" "HOST_IP" S0 S1 E O P YGC YGCT YAVG FGC FGCT FAVG GCT 
  for CUR_HOST in `cat $CONF_FILE | egrep -v ^# |egrep -v ^$`
  do
    ssh -q -l root $CUR_HOST "source /etc/profile; ps -ef|grep tomcat-api |grep -v grep | awk '{print \$2}' |xargs -I {} jstat -gcutil {} |grep -v GC" > ~/gc.log
    gcInfo=`cat ~/gc.log | xargs`   
    gcs=(${gcInfo})
    s0=${gcs[0]}
    s1=${gcs[1]}
    e=${gcs[2]}
    o=${gcs[3]}
    p=${gcs[4]}
    ygc=${gcs[5]}
    ygct=${gcs[6]}
    if [ $ygc -eq 0 ]; then
       yavg=0
    else
       yavg=`echo "scale=3;${ygct}/${ygc}" |bc` 
    fi    
    fgc=${gcs[7]}
    fgct=${gcs[8]}
    if [ $fgc -eq 0 ]; then
       favg=0
    else
       favg=`echo "scale=3;${fgct}/${fgc}" |bc` 
    fi
    gct=${gcs[9]}
   echo -e $CUR_HOST\\t GC:$s0 $s1 $e $o $p $ygc $ygct $yavg $fgc $fgct $favg $gct\\t\\n >> $check_log
    printf " %-8s %-16s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s\n" "GC" $CUR_HOST $s0 $s1 $e $o $p $ygc $ygct $yavg $fgc $fgct $favg $gct
 done
 
}

i=0
while [ $i -lt $COUNT -o $COUNT -eq 0 ]
do
  checkGC
  if [[ $COUNT != 0 ]]; then
    let i++
  fi
  echo " " 
  if [[ $COUNT > 1 ]]; then
    sleep $INTERVAL
  fi
done

