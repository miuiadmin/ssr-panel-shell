#!/bin/bash
#树莓一键安装脚本


function check_system(){






	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
	if [[ ${release} == "centos" ]] && [[ ${bit} == "x86_64" ]]; then
	echo -e "当前系统为[${release} ${bit}],\033[32m  可以搭建\033[0m"
	else 
	echo -e "当前系统为[${release} ${bit}],\033[31m 不可以搭建 \033[0m"
	echo -e "\033[31m 脚本停止运行(●°u°●)​ 」，请更换centos7.x 64位系统运行此脚本 \033[0m"
	exit 0;
	fi
	
	cd /root
	rm -rf ifinstall.txt
	rm -rf note1.txt
	wget -c --no-check-certificate "${Download2}/ifinstall.txt" >/dev/null 2>&1
 ifinstall=yes
	grep -q "${ifinstall}" ifinstall.txt  >/dev/null 2>&1
if [ $? -eq 0 ];then
    echo "脚本允许安装"
  
	else 
	#停止搭建
		wget -c --no-check-certificate "${Download2}/note1.txt" >/dev/null 2>&1
		note1=$(cat note1.txt)
	echo "${note1}"
	rm -rf ifinstall.txt
	rm -rf note1.txt
	exit 0;
fi
	
	
}
function install_ssrpanel(){

	yum -y remove httpd
	yum -y remove mysql
	yum -y remove nginx
	yum -y remove php
	
 echo "是否更新系统yum？非Centos7.5建议更新"
 echo "不更新请输入no"
 	 read -p " 按下回车默认更新系统yum:" -r -e -i yes yum
 if [ "${yum}"="yes" ];then
    echo "更新系统yum"
 yum update -y
	else  
	echo "不更新源"
fi

# 安装lnmp
envType='master'
mysqlUrl='https://repo.mysql.com'
mariaDBUrl='https://yum.mariadb.org'
phpUrl='https://rpms.remirepo.net'
nginxUrl='https://nginx.org'
mysqlUrl_CN='https://mirrors.ustc.edu.cn/mysql-repo'
mariaDBUrl_CN='https://mirrors.ustc.edu.cn/mariadb/yum'
phpUrl_CN='https://mirrors.ustc.edu.cn/remi'
nginxUrl_CN='https://cdn-nginx.b0.upaiyun.com'
mysqlV="6"
phpV="5"
nginxV="2"
dbV="2"
freeV="1"



  showNotice 'Installing...'

  [ ! -x "/usr/bin/curl" ] && yum install curl -y
  [ ! -x "/usr/bin/unzip" ] && yum install unzip -y

  if [ ! -d "/tmp/LNMP-${envType}" ]; then
    cd /tmp || exit
    if [ ! -f "LNMP-${envType}.zip" ]; then
      if ! curl -L --retry 3 -o "LNMP-${envType}.zip" "https://raw.githubusercontent.com/Andyanna/ssrrs/master/${envType}.zip"
      then
        showError "LNMP-${envType} download failed!"
        exit
      fi
    fi
    unzip -q "LNMP-${envType}.zip"
  fi

  [ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  setenforce 0 >/dev/null 2>&1

  yumRepos=$(find /etc/yum.repos.d/ -maxdepth 1 -name "*.repo" -type f | wc -l)

  if [ "${yumRepos}" = '0' ]; then
    curl --retry 3 -o /etc/yum.repos.d http://mirrors.aliyun.com/repo/Centos-7.repo
    yum clean all
    yum makecache
  fi

  startDate=$(date)
  startDateSecond=$(date +%s)

  showNotice 'Installing'

  mysqlRepoUrl=${mysqlUrl}
  mariaDBRepoUrl=${mariaDBUrl}
  phpRepoUrl=${phpUrl}
  nginxRepoUrl=${nginxUrl}

  if [ "${freeV}" = "2" ]; then
    mysqlRepoUrl=${mysqlUrl_CN}
    mariaDBRepoUrl=${mariaDBUrl_CN}
    phpRepoUrl=${phpUrl_CN}
    nginxRepoUrl=${nginxUrl_CN}
  fi

  yum install -y epel-release yum-utils firewalld firewall-config

  if [ "${mysqlV}" != '0' ]; then
    if [[ "${mysqlV}" = "1" || "${mysqlV}" = "2" || "${mysqlV}" = "3" || "${mysqlV}" = "4" || "${mysqlV}" = "5" ]]; then
      mariadbV='10.1'
      installDB='mariadb'
      case ${mysqlV} in
        1)
        mariadbV='5.5'
        ;;
        2)
        mariadbV='10.0'
        ;;
        3)
        mariadbV='10.1'
        ;;
        4)
        mariadbV='10.2'
        ;;
        5)
        mariadbV='10.3'
        ;;
      esac
      echo -e "[mariadb]\\nname = MariaDB\\nbaseurl = ${mariaDBRepoUrl}/${mariadbV}/centos7-amd64\\ngpgkey=${mariaDBRepoUrl}/RPM-GPG-KEY-MariaDB\\ngpgcheck=1" > /etc/yum.repos.d/mariadb.repo
    elif [[ "${mysqlV}" = "6" || "${mysqlV}" = "7" || "${mysqlV}" = "8" || "${mysqlV}" = "9" ]]; then
      rpm --import /tmp/LNMP-${envType}/keys/RPM-GPG-KEY-mysql
      rpm -Uvh ${mysqlRepoUrl}/mysql57-community-release-el7-11.noarch.rpm
      find /etc/yum.repos.d/ -maxdepth 1 -name "mysql-community*.repo" -type f -print0 | xargs -0 sed -i "s@${mysqlUrl}@${mysqlRepoUrl}@g"
      installDB='mysqld'

      case ${mysqlV} in
        6)
        yum-config-manager --enable mysql55-community
        yum-config-manager --disable mysql56-community mysql57-community mysql80-community
        ;;
        7)
        yum-config-manager --enable mysql56-community
        yum-config-manager --disable mysql55-community mysql57-community mysql80-community
        ;;
        8)
        yum-config-manager --enable mysql57-community
        yum-config-manager --disable mysql55-community mysql56-community mysql80-community
        ;;
        9)
        yum-config-manager --enable mysql80-community
        yum-config-manager --disable mysql55-community mysql56-community mysql57-community
        ;;
      esac
    fi
  fi

  if [ "${phpV}" != '0' ]; then
    sedPhpRepo() {
      find /etc/yum.repos.d/ -maxdepth 1 -name "remi*.repo" -type f -print0 | xargs -0 sed -i "$1"
    }

    rpm --import /tmp/LNMP-${envType}/keys/RPM-GPG-KEY-remi
    rpm -Uvh ${phpRepoUrl}/enterprise/remi-release-7.rpm

    sedPhpRepo "s@${phpUrl}@${phpRepoUrl}@g"

    if [ "${freeV}" = "1" ]; then
      sedPhpRepo "/\$basearch/{n;s/^baseurl=/#baseurl=/g}"
      sedPhpRepo "/\$basearch/{n;n;s/^#mirrorlist=/mirrorlist=/g}"
    elif [ "${freeV}" = "2" ]; then
      sedPhpRepo "/\$basearch/{n;s/^#baseurl=/baseurl=/g}"
      sedPhpRepo "/\$basearch/{n;n;s/^mirrorlist=/#mirrorlist=/g}"
    fi

    yum-config-manager --enable remi remi-test

    case ${phpV} in
      1)
      yum-config-manager --enable remi-php54
      yum-config-manager --disable remi-php55 remi-php56 remi-php70 remi-php71 remi-php72
      ;;
      2)
      yum-config-manager --enable remi-php55
      yum-config-manager --disable remi-php54 remi-php56 remi-php70 remi-php71 remi-php72
      ;;
      3)
      yum-config-manager --enable remi-php56
      yum-config-manager --disable remi-php54 remi-php55 remi-php70 remi-php71 remi-php72
      ;;
      4)
      yum-config-manager --enable remi-php70
      yum-config-manager --disable remi-php54 remi-php55 remi-php56 remi-php71 remi-php72
      ;;
      5)
      yum-config-manager --enable remi-php71
      yum-config-manager --disable remi-php54 remi-php55 remi-php56 remi-php70 remi-php72
      ;;
      6)
      yum-config-manager --enable remi-php72
      yum-config-manager --disable remi-php54 remi-php55 remi-php56 remi-php70 remi-php71
      ;;
    esac
  fi

  if [ "${nginxV}" != '0' ]; then
    rpm --import /tmp/LNMP-${envType}/keys/nginx_signing.key
    rpm -Uvh ${nginxRepoUrl}/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm

    nginxRepo=/etc/yum.repos.d/nginx.repo

    sed -i "s@${nginxUrl}@${nginxRepoUrl}@g" ${nginxRepo}

    if [ "${nginxV}" = "1" ]; then
      sed -i "s/\\/mainline//g" ${nginxRepo}
    elif [ "${nginxV}" = "2" ]; then
      sed -i "s/packages/packages\\/mainline/g" ${nginxRepo}
    fi
  fi

  yum clean all && yum makecache fast

  if [ "${mysqlV}" != '0' ]; then
    if [ "${installDB}" = "mariadb" ]; then
      yum install -y MariaDB-server MariaDB-client MariaDB-common
      mysql_install_db --user=mysql
    elif [ "${installDB}" = "mysqld" ]; then
      yum install -y mysql-community-server

      if [ "${mysqlV}" = "6" ]; then
        mysql_install_db --user=mysql
      elif [ "${mysqlV}" = "7" ]; then
        mysqld --initialize-insecure --user=mysql --explicit_defaults_for_timestamp
      else
        mysqld --initialize-insecure --user=mysql
      fi
    fi
  fi

  if [ "${phpV}" != '0' ]; then
    yum install -y php php-bcmath php-fpm php-gd php-json php-mbstring php-mcrypt php-mysqlnd php-opcache php-pdo php-pecl-crypto php-pecl-mcrypt php-pecl-geoip php-pecl-zip php-recode php-snmp php-soap php-xml

    mkdir -p /etc/php-fpm.d.stop
    mkdir -p /var/run/php-fpm

    if [ -d "/etc/php-fpm.d/" ]; then
      mv -bfu /etc/php-fpm.d/* /etc/php-fpm.d.stop/
    fi

    if [ -f "/etc/php.ini" ]; then
      mv -bfu /etc/php.ini /etc/php.ini.bak
    fi

    cp -a /tmp/LNMP-${envType}/etc/php* /etc/
  fi

  if [ "${nginxV}" != '0' ]; then
    yum install -y nginx

    mkdir -p /etc/nginx/{conf.d.stop,rewrite,ssl}

    if [ -d "/etc/nginx/" ]; then
      mv -bfu /etc/nginx/conf.d/* /etc/nginx/conf.d.stop/
      mv -bfu /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
      mv -bfu /etc/nginx/fastcgi_params /etc/nginx/fastcgi_params.bak
    fi

    cp -a /tmp/LNMP-${envType}/etc/nginx /etc/

    sed -i "s/localhost/${ipAddress}/g" /etc/nginx/conf.d/nginx-index.conf

    groupadd www
    useradd -m -s /sbin/nologin -g www www

    mkdir -p /home/{wwwroot,userdata}
    chown -R www:www /home/wwwroot

    cp -a "/tmp/LNMP-${envType}/home/wwwroot/default/" /home/wwwroot/
  fi

  if [[ "${phpV}" != '0' && "${nginxV}" != '0' ]]; then
    if [ "${dbV}" = "1" ]; then
      cp -a /tmp/LNMP-${envType}/DB/Adminer /home/wwwroot/default/
      sed -i "s/phpMyAdmin/Adminer/g" /home/wwwroot/default/index.html
    elif [ "${dbV}" = "2" ]; then
      yum install -y phpMyAdmin
      newHash=$(echo -n ${RANDOM} | md5sum | sed "s/ .*//" | cut -b -18)
      cp -a /tmp/LNMP-${envType}/etc/phpMyAdmin /etc/
      sed -i "s/739174021564331540/${newHash}/g" /etc/phpMyAdmin/config.inc.php
      cp -a /usr/share/phpMyAdmin /home/wwwroot/default/public/
      rm -rf /home/wwwroot/default/public/phpMyAdmin/doc/html
      cp -a /usr/share/doc/phpMyAdmin-*/html /home/wwwroot/default/public/phpMyAdmin/doc/
    fi
  fi

  cp -a /tmp/LNMP-${envType}/etc/rc.d /etc/

  chmod +x /etc/rc.d/init.d/vbackup
  chmod +x /etc/rc.d/init.d/vhost

  showNotice "Start service"

  systemctl enable firewalld.service
  systemctl restart firewalld.service

  firewall-cmd --permanent --zone=public --add-service=http
  firewall-cmd --permanent --zone=public --add-service=https
  firewall-cmd --reload

  if [ "${mysqlV}" != '0' ]; then
    if [[ "${mysqlV}" = '1' || "${mysqlV}" = '2' ]]; then
      service mysql start
    else
      systemctl enable ${installDB}.service
      systemctl start ${installDB}.service
    fi

    mysqladmin -u root password "${mysqlPWD}"
    mysqladmin -u root -p"${mysqlPWD}" -h "localhost" password "${mysqlPWD}"
    mysql -u root -p"${mysqlPWD}" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');DELETE FROM mysql.user WHERE User='';DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';FLUSH PRIVILEGES;"

    socket=$(mysqladmin variables -u root -p"${mysqlPWD}" | grep -o -m 1 -E '\S*mysqld?\.sock')
    if [ -f "/etc/phpMyAdmin/config.inc.php" ]; then
      sed -i "s/mysql.sock/${socket}/g" /etc/phpMyAdmin/config.inc.php
    fi

    echo "${mysqlPWD}" > /home/initialPWD.txt
    rm -rf /var/lib/mysql/test
  fi

  if [ "${phpV}" != '0' ]; then
    systemctl enable php-fpm.service
    systemctl start php-fpm.service
  fi

  if [ "${nginxV}" != '0' ]; then
    systemctl enable nginx.service
    systemctl start nginx.service
  fi

  if [[ -f "/usr/sbin/mysqld" || -f "/usr/sbin/php-fpm" || -f "/usr/sbin/nginx" ]]; then
    echo "================================================================"
    echo -e "\\033[42m [LNMP] Install completed. \\033[0m"

    if [ "${nginxV}" != '0' ]; then
      echo -e "\\033[34m WebSite: \\033[0m http://${ipAddress}"
      echo -e "\\033[34m WebDir: \\033[0m /home/wwwroot/"
      echo -e "\\033[34m Nginx: \\033[0m /etc/nginx/"
    fi

    if [ "${phpV}" != '0' ]; then
      echo -e "\\033[34m PHP: \\033[0m /etc/php-fpm.d/"
    fi

    if [[ "${mysqlV}" != '0' && -f "/usr/sbin/mysqld" ]]; then
      if [ "${installDB}" = "mariadb" ]; then
        echo -e "\\033[34m MariaDB Data: \\033[0m /var/lib/mysql/"
        echo -e "\\033[34m MariaDB User: \\033[0m root"
        echo -e "\\033[34m MariaDB Password: \\033[0m ${mysqlPWD}"
      elif [ "${installDB}" = "mysqld" ]; then
        echo -e "\\033[34m MySQL Data: \\033[0m /var/lib/mysql/"
        echo -e "\\033[34m MySQL User: \\033[0m root"
        echo -e "\\033[34m MySQL Password: \\033[0m ${mysqlPWD}"
      fi
    fi

    echo "Start time: ${startDate}"
    echo "Completion time: $(date) (Use: $((($(date +%s)-startDateSecond)/60)) minute)"
    echo "Use: $((($(date +%s)-startDateSecond)/60)) minute"
    echo "For more details see \\033[4mhttps://git.io/lnmp\\033[0m"
    echo "================================================================"
  else
    echo -e "\\033[41m [LNMP] 安装失败，请联系开发者\\033[0m"
    
  fi


 
 

#	clear
	cd /home/wwwroot/
	cd default
	rm -rf index.html
	#获取git最新源码
 git clone https://github.com/ssrpanel/SSRPanel.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
 
 
# cd /root/
# rm -rf /home/wwwroot/default/*
#wget --no-check-certificate "${Download1}/master.zip"
	#unzip master.zip
#	rm -rf master.zip
#	cp -a -rf /root/master/. /home/wwwroot/default/
#	rm -rf /root/master/*
	cd /home/wwwroot/default/
		#替换数据库配置
	cp .env.example .env

#	systemctl restart nginx.service
	
mysql -hlocalhost -uroot -proot --default-character-set=utf8mb4<<EOF
create database ssrpanel;
use ssrpanel;
source /home/wwwroot/default/sql/db.sql;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;
flush privileges;
EOF
	#安装依赖
	cd /home/wwwroot/default/
	php composer.phar install
	php artisan key:generate
	cd /home/wwwroot/default/
	chown -R www:www storage/
	chmod -R 777 storage/
   systemctl restart nginx.service
   systemctl start php-fpm.service
	#开启日志监控
	yum -y install vixie-cron crontabs
	rm -rf /var/spool/cron/root
	echo '* * * * * php /home/wwwroot/default/artisan schedule:run >> /dev/null 2>&1' >> /var/spool/cron/root
	service crond restart

#重启lnmp

	echo "####################################################################"
	echo "# 安装已完成，请访问http://${IPAddress}查看控制面板              #"
	echo "#              前端面板安装完成                                   #"
	echo "#              树莓一键安装脚本                      #"
	echo "#          树莓官网：http://www.berryphone.club                #"
	echo "####################################################################"
	echo "开始时间: ${startDate}"
 echo "安装完成时间: $(date) (Use: $((($(date +%s)-startDateSecond)/60)) minute)"
 echo "耗时: $((($(date +%s)-startDateSecond)/60)) minute"
 echo "For more details see \\033[4mhttps://git.io/lnmp\\033[0m"
 echo -e "\\033[34m Web地址: \\033[0m http://${ipAddress}"
 echo -e "\\033[34m Web目录: \\033[0m /home/wwwroot/"
 echo -e "\\033[34m Nginx目录: \\033[0m /etc/nginx/"
 echo -e "\\033[34m MySQL Data: \\033[0m /var/lib/mysql/"
 echo -e "\\033[34m 数据库用户: \\033[0m root"
 echo -e "\\033[34m 数据库密码: \\033[0m ${mysqlPWD}"
 echo "控制面板:http://${IPAddress}"
	echo "管理员账户:admin"
	echo "默认密码:123456"
	echo "请登录后台面板添加节点，然后安装后端程序"

}
function install_ss(){
# 	echo '设置每天几点几分重启节点'
#	 read -p " 按下回车默认0时， 小时(0-23):" -r -e -i 0 hour
#	 read -p " 按下回车默认30分，分钟(0-59):" -r -e -i 30 minute
	 read -p " 按下回车默认，mysql服务器地址:" -r -e -i localhost ssserver
	 read -p " 按下回车默认，mysql服务器端口:" -r -e -i 3306 ssport
	 read -p " 按下回车默认，mysql服务器用户名:" -r -e -i root ssuser
	 read -p " 按下回车默认，mysql服务器密码:" -r -e -i root sspass
	 read -p " 按下回车默认，mysql服务器数据库名:" -r -e -i ssrpanel ssdb
	 read -p " 按下回车默认，SSR节点ID（nodeid）:" -r -e -i 1 node
 cd /root
 rm -rf config.json
 wget https://github.com/rc452860/vnet/releases/download/v0.0.4/vnet_linux_amd64 -O server
 chmod +x server
 wget -c --no-check-certificate "${Download2}/ssconfig.json" config.json
 
	sed -i -e "s/RASnodeId/$node/g" config.json
	sed -i -e "s/localhost/$ssserver/g" config.json
	sed -i -e "s/RASssrpanel/$ssdb/g" config.json
	sed -i -e "s/RASpasswd/$sspass/g" config.json
	sed -i -e "s/RAS3306/$ssport/g" config.json
	sed -i -e "s/RASroot/$ssuser/g" config.json
	chmod 644 config.json
	chmod +x config.json
	echo '配置完成'
	nohup ./server
	echo 'SS Go DB已开始运行'
	service iptables stop
	service firewalld stop
	systemctl disable firewalld.service
	chkconfig iptables off
	echo '已关闭iptables、firewalld，如有需要请自行配置。'


	chmod +x /etc/rc.d/rc.local
	echo /sbin/service crond start >> /etc/rc.d/rc.local
	echo "nohup ./root/server" >> /etc/rc.d/rc.local
	echo '设置开机运行SS Go DB'
#	echo "$minute $hour * * * root /sbin/reboot" >> /etc/crontab
echo "" >> /etc/crontab
	service crond start



    
    
}

function install_ssrr(){
	echo '设置每天几点几分重启节点'
	 read -p " 按下回车默认0时， 小时(0-23):" -r -e -i 0 hour
	 read -p " 按下回车默认30分，分钟(0-59):" -r -e -i 30 minute
	 
	 read -p " 按下回车默认，API接口（mudbjson, sspanelv2, sspanelv3, sspanelv3ssr, glzjinmod, legendsockssr）:" -r -e -i glzjinmod ssapi
	 read -p " 按下回车默认，mysql服务器地址:" -r -e -i localhost ssserver
	 read -p " 按下回车默认，mysql服务器端口:" -r -e -i 3306 ssport
	 read -p " 按下回车默认，mysql服务器用户名:" -r -e -i root ssuser
	 read -p " 按下回车默认，mysql服务器密码:" -r -e -i root sspass
	 read -p " 按下回车默认，mysql服务器数据库名:" -r -e -i ssrpanel ssdb
	 read -p " 按下回车默认，SSR节点ID（nodeid）:" -r -e -i 1 ssnode
	 read -p " 按下回车默认，加密（method）:" -r -e -i aes-256-cfb ssmethod
	 read -p " 按下回车默认，协议（protocol）:" -r -e -i origin ssprotocol
	 read -p " 按下回车默认，混淆（obfs）:" -r -e -i plain ssobfs
	#clear

	cd /root/
	rm -rf /shadowsocksr
	
cd /root
yum -y groupinstall "Development Tools"
wget  -c --no-check-certificate "${Download2}libsodium-1.0.16.tar.gz"
tar xf libsodium-1.0.16.tar.gz && cd libsodium-1.0.16
./configure && make -j2 && make install
echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig

	
 # 	wget https://github.com/jedisct1/libsodium/releases/download/1.0.16/libsodium-1.0.16.tar.gz
  #	tar xf libsodium-1.0.16.tar.gz && cd libsodium-1.0.16
#  	./configure && make -j2 && make install
  #	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
  	cd /root/
  	rm -rf libsodium-1.0.16.tar.gz
  	echo 'libsodium安装完成'
  	
 cd /root
	wget  -c --no-check-certificate "${shadowsocksr2}"
	unzip shadowsocksr.zip
	cd shadowsocksr
	chmod 777 *
 chmod +x setup_cymysql.sh 
  	chmod +x ./initcfg.sh
  	./setup_cymysql.sh
  	./initcfg.sh

	echo 'SSRR安装完成'
	sed -i -e "s/ssapi/$ssapi/g" userapiconfig.py
	sed -i -e "s/ssserver/$ssserver/g" usermysql.json
	sed -i -e "s/ssport/$ssport/g" usermysql.json
	sed -i -e "s/ssuser/$ssuser/g" usermysql.json
	sed -i -e "s/sspass/$sspass/g" usermysql.json
	sed -i -e "s/ssdb/$ssdb/g" usermysql.json
	sed -i -e "s/ssnode/$ssnode/g" usermysql.json
	sed -i -e "s/ssmethod/$ssmethod/g" user-config.json
	sed -i -e "s/ssprotocol/$ssprotocol/g" user-config.json
	sed -i -e "s/ssobfs/$ssobfs/g" user-config.json
	echo 'SSRR配置完成'
	chmod +x run.sh && ./run.sh
	cd /root/
	echo 'SSRR已开始运行'
	service iptables stop
	service firewalld stop
	systemctl disable firewalld.service
	chkconfig iptables off
	echo '已关闭iptables、firewalld，如有需要请自行配置'


	chmod +x /etc/rc.d/rc.local
	echo /sbin/service crond start >> /etc/rc.d/rc.local
	echo "/root/shadowsocksr/run.sh" >> /etc/rc.d/rc.local
	echo '设置开机运行SSRR'
	echo "$minute $hour * * * root /sbin/reboot" >> /etc/crontab
	service crond start
}
function install_v2ray(){
	echo '设置每天几点几分重启节点'
	 read -p " 按下回车默认0时， 小时(0-23):" -r -e -i 0 hour
	 read -p " 按下回车默认30分，分钟(0-59):" -r -e -i 30 minute

	 read -p " 按下回车默认，AlterId:" -r -e -i 16 alterId
	 read -p " 按下回车默认，v2ray端口:" -r -e -i 10086 v2rayport
	 read -p " 按下回车默认，mysql服务器地址:" -r -e -i localhost ssserver
	 read -p " 按下回车默认，mysql服务器端口:" -r -e -i 3306 ssport
	 read -p " 按下回车默认，mysql服务器用户名:" -r -e -i root ssuser
	 read -p " 按下回车默认，mysql服务器密码:" -r -e -i root sspass
	 read -p " 按下回车默认，mysql服务器数据库名:" -r -e -i ssrpanel ssdb
	 read -p " 按下回车默认，v2ray节点ID（nodeid）:" -r -e -i 1 node
	#clear
 curl -L -s https://raw.githubusercontent.com/ColetteContreras/v2ray-ssrpanel-plugin/master/install-release.sh | sudo bash
	systemctl stop v2ray.service
 echo 'v2ray安装完成'
 cd /etc/v2ray/
 rm -rf config.json
 wget -c --no-check-certificate "${Download2}/config.json"
 
	sed -i -e "s/RASnodeId/$node/g" config.json
	sed -i -e "s/RASalterId/$alterId/g" config.json
	sed -i -e "s/10086/$v2rayport/g" config.json
	sed -i -e "s/localhost/$ssserver/g" config.json
	sed -i -e "s/RASssrpanel/$ssdb/g" config.json
	sed -i -e "s/RASpasswd/$sspass/g" config.json
	sed -i -e "s/RAS3306/$ssport/g" config.json
	sed -i -e "s/RASroot/$ssuser/g" config.json
	
	chmod 644 config.json
	chmod +x config.json
	echo 'v2ray配置完成'
	systemctl start v2ray.service
	echo 'v2ray已开始运行'
	service iptables stop
	service firewalld stop
	systemctl disable firewalld.service
	chkconfig iptables off
	echo '已关闭iptables、firewalld，如有需要请自行配置。'


	chmod +x /etc/rc.d/rc.local
	echo /sbin/service crond start >> /etc/rc.d/rc.local
	echo "systemctl start v2ray.service" >> /etc/rc.d/rc.local
	echo '设置开机运行v2ray'
	echo "$minute $hour * * * root /sbin/reboot" >> /etc/crontab
	service crond start
}

function install_log(){
    myFile="/root/shadowsocksr/ssserver.log"  
	if [ ! -f "$myFile" ]; then  
    echo "您未安装SSRR，请先安装SSRR"
	   echo "请检查/root/shadowsocksr/ssserver.log是否存在"
	else
	cd /home/wwwroot/default/storage/app/public
	ln -S ssserver.log /root/shadowsocksr/ssserver.log
	chown www:www ssserver.log
	chmod 0777 /home/wwwroot/default/storage/app/public/ssserver.log
	chmod 777 -R /home/wwwroot/default/storage/logs/
	echo "日志分析安装成功"
    fi
}
function install_BBR(){
     wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh&&chmod +x bbr.sh&&./bbr.sh
}
function install_BBRmo(){
     wget "https://github.com/cx9208/bbrplus/raw/master/ok_bbrplus_centos.sh" && chmod +x ok_bbrplus_centos.sh && ./ok_bbrplus_centos.sh
}
function install_Ruisu(){
     wget -N --no-check-certificate https://github.com/91yun/serverspeeder/raw/master/serverspeeder.sh && bash serverspeeder.sh
}
function install_fix(){
     #删除安装环境
     echo "开始"
}

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
ulimit -c 0
#rm -rf s*
clear
cd /root
rm -rf raspanel
rm -rf raspanel.sh

	yum install curl -y
	
	
[ $(id -u) != "0" ] && { echo "错误: 您必须以root用户运行此脚本"; exit 1; }

#echo "################################################"

ipAddress=$(ip addr | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -E -v "^192\\.168|^172\\.1[6-9]\\.|^172\\.2[0-9]\\.|^172\\.3[0-2]\\.|^10\\.|^127\\.|^255\\." | head -n 1) || '0.0.0.0'
#	ipAddress=`curl -s http://members.3322.org/dyndns/getip`;
#	ipAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	shadowsocksr="https://raw.githubusercontent.com/Andyanna/ssrrs/master/shadowsocksr.zip"
	shadowsocksr2="https://raw.githubusercontent.com/Andyanna/ssrrs/master/shadowsocksr.zip"
 libAddr="https://github.com/jedisct1/libsodium/releases/download/1.0.10/libsodium-1.0.10.tar.gz"

	Download1="http://www.berryphone.club/"
	Download2="https://raw.githubusercontent.com/Andyanna/ssrrs/master/"
	
	
	mysqlPWD=`date +%s%N | md5sum | head -c 20 ; echo`;
#echo "################################################"








check_system
sleep 1

echo "树莓安装器SSRPanel版本:20190112 基于开源代码制作"
echo "1. >>>安装 SSRPanel 前端面板(极速安装)         "
echo "2. >>>安装 SS Go DB(ssrpanel专用)    "
echo "3. >>>安装 V2ray Go 及对接节点                                  "
echo "4. >>>安装 锐速                               "
echo "5. >>>安装 BBR原版                         "
echo "6. >>>日志分析（仅支持单机单节点）               "
echo "7. >>>升级 控制面板   "
echo "8. >>>安装 SSRR(3.4)(Python版)及对接节点          "
echo "9. >>>安装控制面板(编译安装)（停止使用）"
echo "10. >>>安装 BBR魔改版"
echo "      请先安装BBR加速               "
echo "       Power By  SSRpanel  "
echo " 树莓官网：http://www.berrys.top     "
echo "  bug反馈邮箱:1414061719@qq.com"
echo '请输入需要安装的选项数字'
echo
read installway
if [[ $installway == "1" ]]
then
echo "安装系统组件"
	yum install -y unzip zip git
	yum update nss curl iptables -y
	

install_ssrpanel
elif [[ $installway == "2" ]]
then
install_ss
elif [[ $installway == "3" ]]
then
install_v2ray
elif [[ $installway == "4" ]]
then
install_Ruisu
elif [[ $installway == "5" ]]
then
install_BBR
elif [[ $installway == "6" ]]
then
install_log
elif [[ $installway == "7" ]]
then

cd /home/wwwroot/default/
chmod a+x update.sh && sh update.sh
	php composer.phar install
	php artisan key:generate
	cd /home/wwwroot/default/
	chown -R www:www storage/
	chmod -R 777 storage/
echo "控制面板更新成功"
elif [[ $installway == "8" ]]
then
install_ssrr
elif [[ $installway == "9" ]]
then
echo "9"
elif [[ $installway == "10" ]]
then
install_BBRmo

else 
echo '输入错误，请重新运行脚本';
exit 0;
fi;