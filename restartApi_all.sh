#/bin/bash

helpInfo(){
    echo "Usage: `basename $0` [options] [ <interval> ]"
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
INTERVAL=${INTERVAL:=10}

if [ $INTERVAL -lt 10 ]; then
   INTERVAL=10
fi

start1=$(date +%s)
for CUR_HOST in `cat $CONF_FILE | egrep -v ^# |egrep -v ^$`
do
  printf "restarting: %-16s ...... " $CUR_HOST
  ./restartApi.sh $CUR_HOST
  sleep $INTERVAL
  printf "OK\n"
done  
end1=$(date +%s)
echo "All Finished. elapse: $(( $end1 - $start1 ))s"
