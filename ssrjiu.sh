#!/bin/bash
#树莓加速器一键安装脚本
#更新日志：



	echo
    echo -e "\033[31m Add a node...\033[0m"
	echo
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
	[ $(id -u) != "0" ] && { echo "错误: 您必须以root用户运行此脚本"; exit 1; }
	echo -e "如果你不知道，你可以直接回车。"
	echo -e "如果连接失败，请检查数据库远程访问是否打开。"
	read -p "请输入您的对接数据库IP   回车默认为本地IP地址  :" Userip
	read -p "请输入数据库名称(回车默认为ssrpanel):" Dbname
	read -p "请输入数据库端口(回车默认为3306):" Dbport
	read -p "请输入数据库帐户(回车默认为root):" Dbuser
	read -p "请输入数据库密码(回车默认为root):" Dbpassword
	read -p "请输入您的节点编号(回车默认为1):  " UserNODE_ID
	IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	Userip=${Userip:-"${IPAddress}"}
	Dbname=${Dbname:-"ssrpanel"}
	Dbport=${Dbport:-"3306"}
	Dbuser=${Dbuser:-"root"}
	Dbpassword=${Dbpassword:-"root"}
	UserNODE_ID=${UserNODE_ID:-"1"}
	
    # 启用supervisord
	echo_supervisord_conf > /etc/supervisord.conf
	sed -i '$a [program:ssr]\ncommand = python /root/shadowsocksr/server.py\nuser = root\nautostart = true\nautorestart = true' /etc/supervisord.conf
	supervisord
	#iptables
	iptables -F
	iptables -X  
	iptables -I INPUT -p tcp -m tcp --dport 22:65535 -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 22:65535 -j ACCEPT
	iptables-save >/etc/sysconfig/iptables
	iptables-save >/etc/sysconfig/iptables
	echo 'iptables-restore /etc/sysconfig/iptables' >> /etc/rc.local
	echo "/usr/bin/supervisord -c /etc/supervisord.conf" >> /etc/rc.local
	chmod +x /etc/rc.d/rc.local
	touch /root/shadowsocksr/ssserver.log
	chmod 0777 /root/shadowsocksr/ssserver.log
	cd /home/wwwroot/default/storage/app/public/
	ln -S ssserver.log /root/shadowsocksr/ssserver.log
    chown www:www ssserver.log
	chmod 777 -R /home/wwwroot/default/storage/logs/

shadowsocksr="https://raw.githubusercontent.com/Andyanna/ssrrs/master/shadowsocksr.zip"
libAddr='https://github.com/jedisct1/libsodium/releases/download/1.0.10/libsodium-1.0.10.tar.gz'

	#yum -y update
	yum -y install git 
	yum -y install python-setuptools && easy_install pip 
	
	#512M chicks add 1 g of Swap
	dd if=/dev/zero of=/var/swap bs=1024 count=1048576
	mkswap /var/swap
	chmod 0644 /var/swap
	swapon /var/swap
	echo '/var/swap   swap   swap   default 0 0' >> /etc/fstab



	cd /root
yum -y groupinstall "Development Tools"
wget  -c --no-check-certificate "${libAddr}"
tar xf libsodium-1.0.10.tar.gz && cd libsodium-1.0.10
./configure && make -j2 && make install
echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig
	
	
	cd /root && rm -rf libsodium*
	yum -y install python-setuptools
	easy_install supervisor
    cd /root
	wget  -c --no-check-certificate "${shadowsocksr}"
	unzip shadowsocksr.zip
	cd shadowsocksr
	
	chmod 777 *
	sh setup_cymysql2.sh
		./initcfg.sh
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/Andyanna/ssrrs/master/user-config.json
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/Andyanna/ssrrs/master/userapiconfig.py
	wget -N -P /root/shadowsocksr/ https://raw.githubusercontent.com/Andyanna/ssrrs/master/usermysql.json
	sed -i "s#Userip#${Userip}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbuser#${Dbuser}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbport#${Dbport}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbpassword#${Dbpassword}#" /root/shadowsocksr/usermysql.json
	sed -i "s#Dbname#${Dbname}#" /root/shadowsocksr/usermysql.json
	sed -i "s#UserNODE_ID#${UserNODE_ID}#" /root/shadowsocksr/usermysql.json
	yum -y install lsof lrzsz
	yum -y install python-devel
	yum -y install libffi-devel
	yum -y install openssl-devel
	yum -y install iptables
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	
	echo "####################################################################"
	echo "#                    成功添加节点请登录到前端站点查看              #"
	echo "#                     正在重新启动系统使节点生效……                 #"
	echo "#                     树莓加速器一键安装脚本                        #"
	echo "#                        官网：http://www.berryphone.club                                           #"
	echo "#                                                                                       #"
	echo "##################################################################"
