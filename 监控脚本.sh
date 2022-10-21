#!/bin/bash
#linux性能监控工具箱
#Description:用于性能监控。
#Data:2020-12-31
#Author:linqiwang
show(){ 	#该函数用于显示磁盘、内存、CPU、网络、IO使用情况
while [ 1 ]	#使用永真循环、条件退出的方式接收用户的猜测并进行判断
do
echo "________________________________________________________________________________________________________________"
echo "磁盘容量使用情况："
df -h
echo "________________________________________________________________________________________________________________"
echo "内存使用情况："
free -m
echo "________________________________________________________________________________________________________________"
echo "CPU使用情况："
iostat -c
p_cpu=`cat /proc/cpuinfo | grep "physical id" | sort | uniq | wc -l`	#获取物理CPU个数
num_cpu=`cat /proc/cpuinfo | grep "cpu cores" | wc -l`			#获取CPU核数
log_cpu=`cat /proc/cpuinfo | grep "processor" | wc -l`			#获取逻辑CPU个数
echo "物理CPU个数：$p_cpu"
echo "CPU核数：$num_cpu"
echo "逻辑CPU个数：$log_cpu"
echo "________________________________________________________________________________________________________________"
echo "网络使用情况："
echo "查看系统当前IP地址：`hostname -I`"
echo "	UDP:";netstat -anu
echo "	TCP:";netstat -st
echo "	接口信息"; sar -n DEV
echo "________________________________________________________________________________________________________________"
echo "IO使用情况:"
iostat -d
        read -p "按任意键刷新  按1退出:" re
        if [ $re == 1 ]
        then
                break	
        fi
done
}
tips(){		#该函数用于报警功能
i=1
read -p "请输入需要监控多少秒：" ti
while [ 1 ]	#使用永真循环、条件退出的方式接收用户的猜测并进行判断
do
n1=`echo $ti|sed 's/[0-9]//g'`
if [ ! -z $n1 ]
then
        echo "请输入数字！"
        break
fi
	echo "-------------正在监控中-------------"
	us=`top -bn1 |grep "%Cpu(s)" |awk -F ":" '{print $2}'| awk -F "." '{print $1}'` 	#获取用户空间占用CPU百分比
	sy=`top -bn1 |grep "%Cpu(s)" |awk -F "us," '{print $2}'|awk -F "." '{print $1}'`	#获取内核空间占用CPU百分比
	cpu=`expr $us + $sy`	#计算CPU的使用情况
	echo "CPU使用率：$cpu%"
	if [ $us -gt 90 ]
	then 
		echo -e "\033[31m警告信息：CPU资源短缺！\033[0m"
	elif [ $sy -gt 90 ]
	then 
		echo -e "\033[31m警告信息：IO资源短缺！\033[0m"

	fi
	used=`free -m | grep 'Mem'| awk '{print $3}'`	#获取已经使用的内存数
	total=`free -m |awk '/Mem/{print $2}'`		#获取内存总数
	free_percent=$[$used*100/$total]		#计算内存使用情况
	echo "内存使用率：$free_percent%"
	if [ $free_percent -gt 80 ] 
	then
		echo -e "\033[31m警告信息：内存资源不足!\033[0m"
	fi
	list=`df -h |grep "^/dev/" > list.txt`		#将磁盘使用情况重定向到list.txt中
	while read line					#遍历list.txt
	do
        	name=`echo $line |awk '{print $1,$NF}'` 	#获取文件系统和挂载点
        	total=`echo $line |awk '{print $2}'`		#获取磁盘容量
        	davail=`echo $line |awk '{print $4}'`		#获取磁盘可用容量
        	percent=`echo $line|awk '{print $5}'|sed 's/%//g'`	#获取磁盘已用容量
		echo "文件系统$name 容量$total 可用$davail 磁盘占用率：$percent%"
        	if [ "$percent" -ge 80 ]
        	then
                	echo -e "\033[31m警告信息：磁盘空间不足！\033[0m"

        	fi
	done <list.txt
	if [ $i == $ti ]
	then
		break
	fi
	sleep 2.5  
	i=`expr $i + 1`
	clear
done
}
process_show(){		#该函数查询进程占用情况
while [ 1 ]   	#使用永真循环、条件退出的方式接收用户的猜测并进行判断
do
	read -p "1)查看占用CPU资源最多的10个进程 2)查看占用内存资源最多的10个进程 3)动态查看进程 4)返回" user
	if [ $user == 1 ]
	then
		ps aux|head -1		#获取标题
		ps aux|grep -v PID|sort -rn -k +3|head		#获取数据
	elif [ $user == 2 ] 
	then
		ps aux|head -1		#获取标题
		ps aux|grep -v PID|sort -rn -k +4|head		#获取数据
	elif [ $user == 3 ]
	then			
		echo "按q退出动态信息"
		top	#可动态获取系统进程情况
	elif [ $user == 4 ]
	then 
		break
	else
		echo "请输入1~4！"
	fi
done
}
process_del(){		#该函数用于杀死特定进程
read -p "请输入要杀死进程的PID:" pid
kill -9 $pid		#该命令用于杀死进程
echo "进程$pid 已被成功杀死！"
}
install(){		#该函数用于检查并安装脚本必需的软件包
echo "正在检查是否已安装必要的软件包....."
sys=`rpm -qa | grep "sysstat"|wc -l`	#检查是否有安装sysstat包
if [ $sys -eq 0 ]
then
        yum -y install sysstat		#安装sysstat软件包
fi
net=`rpm -qa | grep "net-tools"|wc -l`	#检查是否安装net-tools包
if [ $net -eq 0 ]
then
       yum -y install net-tools		#安装net-tools软件包
fi
}
install
clear		#清屏
echo "*************************欢迎使用Linux性能监控系统管理工具箱**********************"	
while [ 1 ]    #使用永真循环、条件退出的方式接收用户的猜测并进行判断
do	
	read -p "1)显示磁盘、内存、CPU、网络、IO使用情况  2)报警功能 3)显示进程资源占用情况 4)杀死特定进程 5)退出 ：" choose
                case $choose in
                        1) show		
                        ;;
                        2) tips	
                        ;;
                        3) process_show
                        ;;
			4) process_del
			;;
                        5) break	#退出
                        ;;
                        *) read -p "1)显示磁盘、内存、CPU、网络、IO使用情况  2)报警功能 3)进程资源占用情况 4)杀死特定进程 5)退出 ："  choose
                        ;;
                esac
done
