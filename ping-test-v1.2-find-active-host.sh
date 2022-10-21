#!/bin/bash
# Author: lqw
#用途：找出特定网段的活跃主机

echo "please input which subnet to scan,for example 192.168.53: "
read subnet
echo "begin to find active host, press ctrl+c to exit"
echo "please wait patiently...."
echo "active-host-list:"
echo "active-host-list:" > active-host-list 
echo "scan time:" >> active-host-list
date >> active-host-list
host_num=0
for ip in $subnet.{165..170}
do
	ping $ip -c 2 &> /dev/null
	if [ $? -eq 0 ]
	then
		echo $ip is active
		echo $ip >> active-host-list
		echo "find time is"+`date` >> active-host-list
		let host_num+=1
	fi
	trap 'exit' SIGINT

done
echo "scan end"
echo "active host num is :  "$host_num
