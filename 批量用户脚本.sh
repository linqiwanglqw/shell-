#!/bin/bash
#linux工具箱
#Description:用于批量查询、增加、删除用户，软件的安装更新和卸载。
#Data:2020-11-19
#Author:linqiwang

#显示主菜单
show() {     
	read -p "1)用户工具箱 2)软件工具箱 3)帮助 4)退出 " lang
}
#显示用户工具箱菜单
userxz(){
        while [ 1 ]  #使用永真循环、条件退出的方式接收用户的猜测并进行判断
        do	
		read -p "1)显示用户 2)批量添加用户 3)批量删除用户 4)返回 ："  user
                case $user in
                        1) usershow	
                        ;;
                        2) uadd		
                        ;;
                        3) udel		
                        ;;
                        4) break	#退出
                        ;;
                        *) read -p "1)显示用户 2)批量添加用户 3)批量删除用户 4)返回 ："  user
                        ;;
                esac
        done
}
#显示系统的用户
usershow(){	
	echo "用户名："		 #使用grep、awk提取用户名
	cat /etc/passwd|grep -v nologin|grep -v halt|grep -v shutdown|grep -v sync|awk -F":" '{print $1}'     
	echo "用户数量："	#使用wc -l显示行数
	cat /etc/passwd|grep -v nologin|grep -v halt|grep -v shutdown|grep -v sync|awk -F":" '{print $1}' | wc -l
	read -p "是否保存全部用户名？(y/n)" yn
	if [ y == $yn ]
	then	
		read -p "请输入保存在文本文档的名称：" u_name
		tx=$u_name.txt
		cat /etc/passwd|grep -v nologin|grep -v halt|grep -v shutdown|grep -v sync|awk -F":" '{print $1}' >$tx
		echo "保存成功！"
	fi
}
#批量添加用户
uadd() {   
	read -p "请输入账号数数量：" user_num
	read -p "请输入用户名；" user_px
	read -p "请输入账号初始密码：" user_pw
	read -p "请输入账号失效时间(年-月-日)：" user_etime
	i=1
	while [ $i -le $user_num ]
	do 	
		if [ $i -lt 10 ]
		then
			a="${user_px}0$i"	#对小于10的数字加0 如输入6输出06，并加上用户名
		else
			a="${user_px}$i"	#对大于10直接加上用户名
		fi
		useradd -e $user_etime $a
		echo $user_pw |passwd --stdin $a &> /dev/rull   #标准输出和标准错误输出都重定向到Linux黑洞中
		let i++
	done			

}
#批量删除用户
udel() {    
	read -p "请输入需要删除的用户名：" px
	read -p "请输入需要删除的数量：" num
	sum=1
	while [ $sum -le $num ]
        do
        	if [ $sum -lt 10 ]
                then
                	na="${px}0$sum"		#对小于10的数字加0 如输入6输出06，并加上用户名
                else
                        na="${px}$sum"		#对大于10直接加上用户名
                fi
                userdel -r $na
                let sum++
        done
}
#显示软件工具箱菜单
Softwarexz(){
        while [ 1 ]    #使用永真循环、条件退出的方式接收用户的猜测并进行判断
        do
                read -p "1)查看已安装的软件 2)安装软件 3)升级软件 4)卸载 5)返回 ："  sz
                case $sz in
                        1) sshow	
                        ;;
                        2) sin
                        ;;
                        3) sup
                        ;;
			4) sun
			;;
                        5) break
                        ;;
                        *) read -p "1)查看已安装的软件 2)安装软件 3)升级软件 4)卸载 5)返回 ："  sz
                        ;;
                esac
        done
}
#查看已安装的软件
sshow(){    
	yum info installed

}
#安装软件
sin(){		
	read -p "请输入需要安装的软件：" in
	yum install $in
}
#升级软件
sup(){     
	read -p "请输入需要升级的软件：" up
	yum update $up
}
#卸载软件
sun(){   
	read -p "请输入需要卸载的软件：" u
	yum remove $u
}
echo "*********欢迎使用Liunx工具箱************"	
while [ 1 ]    ##使用永真循环、条件退出的方式接收用户的猜测并进行判断
do	      
	show
	case $lang in
		1) echo "正在进入用户工具箱"  
		 userxz
   		;;
		2) echo "正在进入软件工具箱"
		Softwarexz
		;;
		3) echo "用户工具箱用于批量处理用户信息，软件工具箱用于软件的处理。" 
		;;
		4) break
		;;
		*) show 
		;;
	esac
done

