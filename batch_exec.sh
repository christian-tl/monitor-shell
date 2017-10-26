#/bin/bash

helpInfo(){
    echo "Usage: `basename $0` [options] [ <interval> [ <interval> [ <count> ]]"
    echo "options are:"
    echo "    -h : host ip file, or ip list separated by commas"
    echo "    -c : command"
}

if [[ $# < 4 ]];then
   helpInfo;
   exit 1
fi

while getopts 'h:c:' OPT; do
  case $OPT in
    h)
        CONF_INFO="$OPTARG";;
    c)
        EXE_COMMAND="$OPTARG";;
    ?)
        helpInfo
    exit 1
  esac
done

if [[ $# = 5 || $# > 5 ]];then
  INNER_INTERVAL=$5
  INTERVAL=$6
  COUNT=$7
fi

INNER_INTERVAL=${INNER_INTERVAL:=1}
INTERVAL=${INTERVAL:=1}
COUNT=${COUNT:=1}

blue=`tput setaf 4`
reset=`tput sgr0`

exec_cmd(){
  if [ ! -f $CONF_INFO ]; then
    iplist=`echo $CONF_INFO |xargs -d ","`
  else
    iplist=`cat $CONF_INFO | egrep -v ^# |egrep -v ^$`
  fi
  for CUR_HOST in $iplist
  do
     printf "${blue}%-16s ${reset} \n" $CUR_HOST
     ssh -fnq -l root $CUR_HOST "source /etc/profile; ${EXE_COMMAND} ; exit;"
     sleep $INNER_INTERVAL 
     printf "\n"
  done
}

i=0
while [ $i -lt $COUNT -o $COUNT -eq 0 ]
do
  exec_cmd
  if [[ $COUNT != 0 ]]; then
    let i++
  fi
  if [[ $COUNT > 1 ]]; then
    sleep $INTERVAL
  fi
done
