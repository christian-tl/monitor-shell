#!/bin/bash

./checkMem.sh -h conf/stock_hosts.conf
./checkCpu.sh -h conf/stock_hosts.conf 
./checkDisk.sh  -h conf/stock_hosts.conf
./checkConnection.sh -h conf/connection_check_hosts.conf 
./checkApi.sh -h conf/stock_api_hosts.conf -p 8016 -i conf/stock_api_request.conf
