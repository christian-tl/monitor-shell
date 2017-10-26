#/bin/bash

helpInfo(){
    echo "Usage: `basename $0` [options]"
    echo "options are:"
    echo "    -h : host ip file"
    echo "    -s : source file or dir"
    echo "    -d : destination dir"
}

if [[ $# < 6 ]];then
   helpInfo;
   exit 1
fi

while getopts 'h:s:d:' OPT; do
  case $OPT in
    h)
        CONF_F="$OPTARG";;
    s)
        SRC_F="$OPTARG";;
    d)
        DEST_F="$OPTARG";;
    ?)
        helpInfo
    exit 1
  esac
done

blue=`tput setaf 4`
reset=`tput sgr0`

exec_scp(){
  if [ ! -f $CONF_F ]; then
    iplist=`echo $CONF_F |xargs -d ","`
  else
    iplist=`cat $CONF_F | egrep -v ^# |egrep -v ^$`
  fi
  for CUR_HOST in $iplist
  do
     printf "${blue}%-16s ${reset}\n" $CUR_HOST
     scp -r $SRC_F root@$CUR_HOST:$DEST_F
     echo ""
     sleep 1 
  done
}

exec_scp
