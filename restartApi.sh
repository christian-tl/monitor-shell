#!/bin/bash

# usage: restartApi.sh 10.4.12.130 10.4.12.26

shutdown_cmd=/usr/local/tomcat_prodstock_new/bin/shutdown.sh
startup_cmd=/usr/local/tomcat_prodstock_new/bin/startup.sh
ps_key=tomcat_prodstock_new

for i in $@
do
  ssh -fnq -l root $i "source /etc/profile; ps -ef |grep java |grep $ps_key |grep -v grep |awk '{print \$2}' | xargs -I {} kill -9 {}; sleep 1; $startup_cmd ; exit;"
done
