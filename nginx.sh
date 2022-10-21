#!/bin/bash
#Author: lqw

install(){
pcre=`rpm -qa |grep pcre-devel`
if [ $pcre ]
then
	echo "pcre已安装！"
else
	yum install -y pcre pcre-devel
fi
openssl=`rpm -qa |grep openssl-devel`
zlib=`rpm -qa |grep zlib-devel`
gc=`rpm -qa |grep gcc-c++`
if [ $openssl -a $zlib -a $gc ]
then
        echo "其余四个依赖已安装！"
else
	yum -y install make zlib zlib-devel gcc-c++ libtool openssl openssl-devel
fi
/usr/local/nginx/sbin/./nginx &>null
sleep 2
two=`ps -ef |grep "nginx: worker process" |wc -l`
if [ $two -eq 1 ]
then
	echo "Nginx已安装!请勿重复安装"
else
	pcre=`rpm -qa |grep wget`
	if [ $pcre ]
	then
        	echo "wget已安装！"
	else
        	yum install -y wget
	fi
	wget -P /usr/src http://nginx.org/download/nginx-1.20.1.tar.gz 
	echo "nginx-1.20.1.tar.gz下载成功！"
	tar -zxvf /usr/src/nginx-1.20.1.tar.gz  -C /usr/src
	sleep 2
	cd /usr/src/nginx-1.20.1/	
	./configure
	cd /usr/src/nginx-1.20.1/
	make && make install
	echo "安装成功！"
	/usr/local/nginx/sbin/./nginx &>null
	sleep 1
	success=`ps -ef |grep "nginx: worker process" |wc -l`
	if [ $success -eq 1 ]
	then
		echo "Nginx启动成功！ "
		firewall-cmd --add-service=http --zone=public --permanent &>null
		firewall-cmd --add-port=80/tcp --permanent &>null
		firewall-cmd --reload &>null
		success=`grep "proxy_pass http://myserver;" /usr/local/nginx/conf/nginx.conf`
		if [ "$success" ]
		then
        		echo ""
		else
        		sed -i "45 a #proxy_pass http://myserver;" /usr/local/nginx/conf/nginx.conf
		fi

	else 
		echo "启动失败！"
	fi
fi
}

load_balancing(){
echo "请按下面格式输入服务器列表内所有的IP地址和端口"
echo "轮询(server 192.168.199.106:8081; server 192.168.199.102:8082;)："
echo "按照权重(server 192.168.199.106:8081 weight=1; server 192.168.199.102:8082 weight=10;)："
echo "ip的hash结果分配(ip_hash; server 192.168.199.106:8081; server 192.168.199.102:8082;)："
read name
list="    upstream myserver { $name }"
num=`grep "proxy_pass http://" -n /usr/local/nginx/conf/nginx.conf |awk -F ':' '{print $1}'`
sed -i "$num c proxy_pass http://myserver;" /usr/local/nginx/conf/nginx.conf | &>/dev/null
N=`grep 'upstream myserver' -n /usr/local/nginx/conf/nginx.conf  |awk -F ':' '{print $1}'`
if [ $N ]
then
	sed -i "$N d" /usr/local/nginx/conf/nginx.conf
	n=$[$N-1]
	sed -i "$n a $list" /usr/local/nginx/conf/nginx.conf
else	
	sed -i "33 a $list" /usr/local/nginx/conf/nginx.conf
fi
plan
}
plan(){
rm -rf /root/text.txt
work=`ps -ef |grep "nginx: worker process"`
cd /usr/local/nginx/sbin/
if [ "$work" ]
then
./nginx -s reload &>/root/text.txt
judge1=`cat /root/text.txt`
	if [ "$judge1" ]
	then
        	echo "请重新按格式输入！"
	fi
echo "修改成功！"
else
./nginx &>/dev/null
./nginx -s reload &>/root/text.txt
judge2=`cat /root/text.txt`
	if [ "$judge2" ]
	then
        	echo "请重新按格式输入！"
	fi
echo "修改成功！"
fi
}

journal(){

read -p "是否显示查询某天的页面访问量(Y)" YN
if [ $YN == 'Y' ]
then 
	echo "请输入日月年(11/Jun/2021):"
	read date1
fi
clear
echo "==============================日志分析==============================="
if [ $date1 ]
then
	echo "$date1 当天页面的访问量："
	day=`echo $date1|awk -F "/" '{print $1}'`
	month=`echo $date1|awk -F "/" '{print $2}' `
	year=`echo $date1|awk -F "/" '{print $3}'`
	cat /usr/local/nginx/logs/access.log |sed -n "/$day\/$month\/$year/p" | wc -l
	echo ""
fi		
echo "页面总访问量:"
journal2=`cat /usr/local/nginx/logs/access.log |wc -l`
echo "$journal2"
echo ""
echo "今天页面的访问量："
english_month=`date -R |awk '{print $3}'`
journal3=$(cat /usr/local/nginx/logs/access.log|sed -n /`date "+%d\/$english_month\/%Y"`/p |wc -l)
echo "$journal3"
echo ""
echo "访问的IP个数:"
journal4=`cat /usr/local/nginx/logs/access.log | awk '{print $1}' | sort -k1 -r | uniq | wc -l`
echo "$journal4"
echo ""
echo "每小时的请求数量："
journal5=`cat /usr/local/nginx/logs/access.log | awk '{print $4}'|awk -F ":" '{print $2}' | uniq -c| awk '{print "时间："$2"点   次数："$1}'|sort -k1`
echo "$journal5"
echo ""
echo "访问次数最多的前10个IP:"
echo "    次数       IP"
journal6=`cat /usr/local/nginx/logs/access.log |awk '{print $1}' | sort |uniq -c | sort -nr | head -n 10`
echo "$journal6"
echo ""
echo "访问次数超过300次的前10个IP:"
echo "    次数       IP "
journal7=`cat /usr/local/nginx/logs/access.log |awk '{print $1}' | sort |uniq -c | sort -nr | awk '{if($1>300) print $0 }'| head -n 10`
echo "$journal7"
echo ""
echo "状态码情况:"
echo "   次数 状态码"
journal8=`cat /usr/local/nginx/logs/access.log|awk '{print $9}'|sort|uniq -c | sort -nr`
echo "$journal8"
read -p "每分钟的请求数量过多是否显示:(Y)"  show_num
if [ $show_num == 'Y' ]
then
	echo "每分钟的请求数量"
	echo "    次数 时间"
	cat /usr/local/nginx/logs/access.log | awk '{print $4}'|awk -F ":" '{print $2":"$3}' | uniq -c|sort -k1
fi
echo "====================================================================="

read -p "是否将上述数据保存：(Y)" save
if [ $save == 'Y' ]
then	
	mkdir /root/log &>null
	text_name=`date "+/root/log/%Y-%m-%d--%H:%M.txt"`
	if [ -e "$text_name"  ] 
	then
		rm -rf $text_name
	fi
	echo "页面的总访问量：$journal2" >> $text_name
	echo "今天页面的访问量：$journal3" >> $text_name
	echo "访问的IP个数: $journal4">> $text_name
	echo "每小时的请求数量：">> $text_name
	echo "$journal5">>$text_name
	echo "访问次数最多的前10个IP:">> $text_name
	echo "$journal6">>$text_name
	echo "访问次数超过300次的前10个IP:">> $text_name
	echo "$journal7">> $text_name
	echo "状态码情况:">> $text_name
	echo "$journal8">> $text_name
	echo "数据已保存至$text_name"		
	echo "每分钟的请求数量已保存为access.csv"
	cat /usr/local/nginx/logs/access.log | awk '{print $4}'|awk -F ":" '{print $2":"$3}' | uniq -c| awk '{print $2","$1}'|sort -k1 | awk '{print $2","$1}'> /root/log/access.csv
fi
}	
clear	
while [ 1 ]    ##使用永真循环、条件退出的方式接收用户的猜测并进行判断
do
	echo ""
	echo "********************************"
	echo "1.安装Nginx服务器并运行"
	echo "2.Nginx服务器配置负载均衡"
	echo "3.Nginx服务器日志分析"
	echo "0.退出"
	echo "********************************"	      
	read -p "请选择（0-3）：" choose
                case $choose in
                        1) 
			install
                        ;;
                    	2)
			load_balancing 
                        ;;
                        3) 
			journal
			;;	
                        0) break        #退出
                        ;;
	esac
done
