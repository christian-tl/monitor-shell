#!/bin/bash

source ./setenv.sh

helpInfo(){
   echo "Usage: `basename $0` [options] [ <interval> [ <count> ] ]"
   echo "options are:"
   echo "    -h : host ip file"
   echo "    -p : port"
   echo "    -i : requst info file：uri paramters method content-type timeout response-code"
}

while getopts 'h:p:i:' OPT; do
    case ${OPT} in
      h)
          REQ_HOSTS="$OPTARG";;
      p)
          REQ_PORT="$OPTARG";;
      i)
          REQ_INFO="$OPTARG";;
      ?)
          helpInfo
      exit 1
    esac
done

if [[ $# < 6 ]];then
   helpInfo;
   exit 1
fi

INTERVAL=$7
COUNT=$8
INTERVAL=${INTERVAL:=1}
COUNT=${COUNT:=1}
REQ_PORT=${REQ_PORT:=80}

checkApi(){
  check_date=`date "+%Y-%m-%d_%H-%M"`
  check_fail_log="$LOG_PATH/check_api_fail_$check_date.txt"
  printf " ${blue}%-8s %-16s %-8s %-36s %-8s${reset}\n" "ITEM" "HOST_IP" "PORT" "REQUEST_URI" "STATUS"
  for CUR_HOST in $(cat ${REQ_HOSTS} | egrep -v ^# |egrep -v ^$)
  do
    cat ${REQ_INFO} | egrep -v ^# |egrep -v ^$ | while read INFO
    do
       info=(${INFO})
       req_url="http://$CUR_HOST:$REQ_PORT${info[0]}"
       req_param=${info[1]}
       req_method=${info[2]}
       ctx_type=${info[3]}
       timeout=${info[4]}
       res_code=${info[5]}
       if [ $req_method == "GET" ]; then
          req_url="${req_url}?${req_param}"
       elif [ $req_method == "POST" ]; then
          req_data=" -d ${req_param}"
       fi
       if curl -s -i -o /dev/null -w %{http_code}"\n" --connect-timeout ${timeout} -H ${ctx_type} -X ${req_method} ${req_url} ${req_data} | grep -q ${res_code};then
          printf " %-8s %-16s %-8s %-36s %-8s\n" "API" ${CUR_HOST} ${REQ_PORT} ${info[0]} "OK"
      else
          date_str=`date "+%Y-%m-%d %H:%M:%S"`
          printf "${red} %-8s %-16s %-8s %-36s %-8s${reset}\n" "API" ${CUR_HOST} ${REQ_PORT} ${info[0]} "Invalid"
          echo -e "$date_str\\t API\\t $CUR_HOST\\t $REQ_PORT\t\t ${info[0]}\\t Invalid!\\n" >> ${check_fail_log}
      fi
    done
  done

  if [ -f ${check_fail_log} ]; then
     mail -s "[MonitoringAlarm] Service API Invalid!" -c $MAIL_TO < ${check_fail_log}
     #rm -rf $check_fail_log
  fi
}

i=0
while [ ${i} -lt ${COUNT} -o $COUNT -eq 0 ]
do
  checkApi
  if [[ $COUNT != 0 ]]; then
    let i++
  fi  
  echo " "
  if [[ $COUNT > 1 ]]; then
    sleep $INTERVAL
  fi
done
