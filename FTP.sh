#!/bin/bash
#this program is control ftp server
#Data:2020-4-20
#Author:lqw

InstallFTP(){	#安装FTP服务器
install=`rpm -qa|grep vsftpd`	#判断是否安装FTP服务器
if [ $install ]
then
	edition="$install"
        echo "FTP服务器已安装！"
        echo "版本为 $edition"	#FTP服务器已安装，则输出版本号
else
	yum install -y vsftpd	#FTP服务器未安装，则安装ftp软件包
	clear
	echo "FTP服务器安装成功！"
fi
}
RunFTP(){	#配置防火墙
systemctl start firewalld	#启动防火墙
systemctl enable firewalld	#开机自动启动vsftpd
firewall-cmd --add-service=ftp --permanent	#把firewalld服务中的请求ftp服务器设置为永久
firewall-cmd --reload	#立即生效
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config	#关闭SELinux
}
FTPUseradd() {	#批量添加ftp用户
read -p "请输入账号数数量：" user_num
read -p "请输入用户名；" user_px
read -p "请输入账号初始密码：" user_pw
i=1
while [ $i -le $user_num ]
do
	a="${user_px}$i"
        useradd  -s  /sbin/nologin $a	#创建ftp账户
        echo $user_pw|passwd --stdin $a &> /dev/rull	#设置密码，标准输出和标准错误输出都重定向到Linux黑洞中
        echo "username: $a password: $user_pw" >> user.txt	#将账号密码追加到user.txt文件中
        let i++
done
echo "所有FTP用户密码已保存在user.txt文件中"                    
}
FTPUserdel() {	#批量删除ftp用户
read -p "请输入需要删除的用户名：" px
read -p "请输入需要删除的数量：" num
sum=1
while [ $sum -le $num ]
do
        na="${px}$sum"
        userdel -r $na	#删除ftp用户
	sed -i '/^username: '$na'/d' user.txt	#删除user.txt中的需要删除ftp用户和密码
        let sum++
done
echo "删除成功！"
}
user_log(){	#查询用户日志
read -p "请输入需要查询的用户日志：" ftp_user
judge=`cat /var/log/xferlog | awk '{print $14,$15}'|grep "$ftp_user ftp"`	#通过查找第14列加第15列是否出现用户名加 ftp来判断是否有该用户的日志信息
if [ "$judge" ]
then
        content=`cat /var/log/xferlog |grep "$ftp_user" |awk '{print "用户名："$14"  当前时间："$1,$2,$3,$4,$5 " 传输时间：" $6 "秒 文件大小："$8 "byte  文件名："$9"  输出方向："$12"  访问模式："$13 }'`	#通过grep查找到该用户的行，再通过awk找到所需要信息的列
        echo "$content "

else
        echo "用户不存在"
fi
}
Anonymous(){	#切换匿名模式
cp /etc/vsftpd/vsftpd.conf.anon /etc/vsftpd/vsftpd.conf
systemctl restart vsftpd
clear
echo "匿名模式已生效!"
}	
Local(){	#切换本地模式
cp /etc/vsftpd/vsftpd.conf.local /etc/vsftpd/vsftpd.conf
systemctl restart vsftpd
clear
echo "本地模式已生效!"
}
adduser_chroot(){	#启用chroot技术
test=`grep "anon_root" /etc/vsftpd/vsftpd.conf`
if [ $test ]	#判断是否为本地模式
then 
	echo "本地模式未生效!"
        read -p "是否切换为本地模式(yes or no)" choice
        if [ $choice==yes ]
        then
 		Local	#切换到本地模式
		adduser_chroot         #重新调用该函数      
        else
                break
                clear
        fi
else
        test1=`grep "chroot_list_enable" /etc/vsftpd/vsftpd.conf`	#判断是否有chroot_list_enable这一行
        if [ "$test1" ]
       	then
                sed -i 's/chroot_list_enable=NO/chroot_list_enable=YES/' /etc/vsftpd/vsftpd.conf	#修改配置文件
        else
                echo "chroot_list_enable=YES" >>/etc/vsftpd/vsftpd.conf		#直接添加
        fi
        test2=`grep "chroot_list_file" /etc/vsftpd/vsftpd.conf`		#判断是否有chroot_list_file这一行
        if [ "$test2" ]
        then
                sed -i '/^chroot_list_file/d' /etc/vsftpd/vsftpd.conf	#删除chroot_list_file开头的行
                echo "chroot_list_file=/etc/vsftpd/chroot_list" >>/etc/vsftpd/vsftpd.conf	#修改配置文件
        else
                echo "chroot_list_file=/etc/vsftpd/chroot_list" >>/etc/vsftpd/vsftpd.conf	#修改配置文件
        fi
        systemctl restart vsftpd	#重启
        read -p "请输入需要chroot技术的FTP用户名：" username
        test3=`grep "$username" /etc/vsftpd/chroot_list`	#判断chroot_list中是否存在该用户
        if [ $test3 ]
        then
                echo "用户已存在！"
       	else
                echo "$username" >>/etc/vsftpd/chroot_list	#将用户添加进chroot_list中
                echo "执行成功！"       
        fi	
fi
}
blacklist(){	#添加黑名单
test4=`grep "anon_root" /etc/vsftpd/vsftpd.conf`
if [ $test4 ]
then 
	echo "本地模式未生效!"
        read -p "是否切换为本地模式(yes or no)" choice
        if [ $choice==yes ]
        then
 		Local
		blacklist               
        else
                break
                clear
        fi
else
        test5=`grep "userlist_file" /etc/vsftpd/vsftpd.conf`
        if [ "$test5" ]
       	then
                sed -i '/^userlist_file/d' /etc/vsftpd/vsftpd.conf
                echo "userlist_file=/etc/vsftpd/user_list" >>/etc/vsftpd/vsftpd.conf
        else
                echo "userlist_file=/etc/vsftpd/user_list" >>/etc/vsftpd/vsftpd.conf
        fi
        systemctl restart vsftpd
        read -p "请输入需要加入黑名单的FTP用户名：" blacklist_username
        test6=`grep "$blacklist_username" /etc/vsftpd/user_list`
        if [ $test6 ]
        then
                echo "用户已存在！"
       	else
                echo "$blacklist_username" >>/etc/vsftpd/user_list
                echo "执行成功！"       
        fi	
fi
}

  
clear	
while [ 1 ]    ##使用永真循环、条件退出的方式接收用户的猜测并进行判断
do
	echo ""
	echo "********************************"
	echo "1.安装FTP服务器，并配置防火墙"
	echo "2.批量添加ftp用户"
	echo "3.批量删除ftp用户"
	echo "4.查询用户日志"
	echo "5.切换匿名模式"
	echo "6.切换本地模式"
	echo "7.启用chroot技术"
	echo "8.添加黑名单"
	echo "0.退出"
	echo "********************************"	      
	read -p "请选择（0-8）：" choose
                case $choose in
                        1) InstallFTP
			RunFTP
                        ;;
                    	2) FTPUseradd
                        ;;
                        3) FTPUserdel
                        ;;
			4) user_log
			;;
			5) Anonymous
			;;
			6) Local
			;;
			7) adduser_chroot
			;;
			8) blacklist
			;;	
                        0) break        #退出
                        ;;
	esac
done
