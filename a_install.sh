#!/bin/bash

# Filename    : a_install.sh
# Author      : shenzhe
# Vsion       : 1.1
# UpdateDate  : 2017/04/13
# Description : this script used to install tomcat, dataserver, superMap, toolsDownload and set default tomcat memory size 512m~1024m,
#               you need put the datamonitorserver or apache-tomcat-7.0.63.tar.gz or toolsDownlad in /tmp

system_name=0 # like index/monitor/guide/...
install_path=0 # like /home/yuantiaotech/project
database_name=0 # indexmonitor/monitor/guide/...
script_path=$(cd "$(dirname "$0")"; pwd) # current script path
server_port=0 # for dataserver
shutdow_port=8005 # for tomcat
http_port=8081 # for tomcat
redirect_port=8443 # for tomcat
ajp_port=8009 # for tomcat
tomcat_path=0 # for tomcat
port_add=0 # for tomcat
tomcat_package=apache-tomcat-7.0.63 # tomcat package name
dataserver_package=datamonitorserver # dataserver package name
user_name=yuantiaotech

tomcatInstall(){
	# check path
	if [ ! -d $install_path ]; then
	    mkdir $install_path
	else
	    echo "$install_path already existd"
	fi

	if [ ! -d /tmp/$tomcat_package ]; then
		tar -zxvf /tmp/$tomcat_package.tar.gz -C /tmp
		sleep 5
	else
		echo "$tomcat_package already unpacked"
	fi

	tomcat_path=$install_path/tomcat_$system_name

	if [ ! -d $tomcat_path ]; then
		cp -r /tmp/$tomcat_package $tomcat_path  # copy & rename
	else
		echo "$tomcat_path already existd"
	fi

	# config TOMCAT_HOME in /etc/profile
	if cat /etc/profile | grep CATALINA_HOME_$system_name >/dev/null 
		then
	    echo "TOMCAT_HOME_$system_name in /etc/profile already existd"	
	else
	    echo "configure tomcat_$system_name in /etc/profile"
		echo "123456"|sudo -S sed -i '$a##########'$(echo $system_name)' tomcat##########' /etc/profile
		echo "123456"|sudo -S sed -i '$aTOMCAT_HOME_'$(echo $system_name)'='$(echo $tomcat_path)'' /etc/profile
		echo "123456"|sudo -S sed -i '$aCATALINA_HOME_'$(echo $system_name)'='$(echo $tomcat_path)'' /etc/profile
		echo "123456"|sudo -S sed -i '$aCATALINA_BASE_'$(echo $system_name)'='$(echo $tomcat_path)'' /etc/profile
		echo "123456"|sudo -S sed -i '$aexport TOMCAT_HOME_'$(echo $system_name)'  CATALINA_HOME_'$(echo $system_name)'  CATALINA_BASE_'$(echo $system_name)'' /etc/profile
		echo "123456"|sudo -S sed -i '$a##########'$(echo $system_name)' tomcat##########' /etc/profile
	fi
	sleep 1
	echo "TOMCAT_HOME&TOMCAT_BASE in /etc/profile configure success"

	# config CATALINA_HOME&CATALINA_BASE in $tomcat_path/bin/catalina.sh
	if cat $tomcat_path/bin/catalina.sh | grep CATALINA_HOME_$system_name >/dev/null 
		then
	    echo "TOMCAT_HOME_$system_name in $tomcat_path/bin/catalina.sh already existd"
	else
		sed -i "s/CATALINA_HOME/CATALINA_HOME_$system_name/g" $tomcat_path/bin/catalina.sh
	    echo "configure CATALINA_HOME_$system_name in $tomcat_path/bin/catalina.sh success"
	fi
	sleep 1

	if cat $tomcat_path/bin/catalina.sh | grep CATALINA_BASE_$system_name >/dev/null 
		then
	    echo "TOMCAT_BASE_$system_name in $tomcat_path/bin/catalina.sh already existd"
	else
		sed -i "s/CATALINA_BASE/CATALINA_BASE_$system_name/g" $tomcat_path/bin/catalina.sh
	    echo "configure CATALINA_BASE_$system_name in $tomcat_path/bin/catalina.sh success"
	fi
	sleep 1

	# set tomcat memory & report
	sed -i "1 aJAVA_OPTS='-server -Xms512m -Xmx1024m -XX:PermSize=64m -XX:MaxPermSize=256m -Djava.awt.headless=true -DFile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8'" $tomcat_path/bin/catalina.sh
	sed -i "1 aexport LC_ALL=\"zh_CN.UTF-8\"" $tomcat_path/bin/catalina.sh
	echo "configure tomcat memory & report in $tomcat_path/bin/catalina.sh success"
	sleep 1
	
	# config the port in $tomcat_path/conf/server.xml
	sed -i "s/8005/$shutdow_port/g" $tomcat_path/conf/server.xml
	sed -i "s/8081/$http_port/g" $tomcat_path/conf/server.xml
	sed -i "s/8443/$redirect_port/g" $tomcat_path/conf/server.xml
	sed -i "s/8009/$ajp_port/g" $tomcat_path/conf/server.xml
	echo "configure tomcat_$system_name port success"
	echo "Shutdown Port:$shutdow_port"
	echo "HTTP/1.1 Port:$http_port"
	echo "Redirect Port:$redirect_port"
	echo "AJP/1.3 Port:$ajp_port"
}

toolsDownloadInstall(){
	#copy web.xml&favicon.ico&file to tomcat
	cp /tmp/toolsDownload/web.xml $tomcat_path/conf/
	cp /tmp/toolsDownload/favicon.ico $tomcat_path/webapps/ROOT/
	cp -r /tmp/toolsDownload/toolsDownload $tomcat_path/webapps/

	echo "tomcat_$system_name install success"
}

geoserverInstall(){
	if [ $system_name=geoMap ]; then
		#copy geoserver.war to tomcat
		cp -r /tmp/geoserver.war $tomcat_path/webapps/
	elif [ $system_name=geoLayer ]; then
		#copy geoserver to tomcat
		cp -r /tmp/geoserver $tomcat_path/webapps/
	fi
	
	echo "tomcat_$system_name install success"
}

supermapInstall(){
	supermap_path=$install_path/SuperMapiServer7C
	if [ ! -d $supermap_path ]; then
		tar -zxvf /tmp/supermap_iserver_7.1.2_linux64.tar.gz -C $install_path
		sleep 50
		echo "Supermap unpacked"
	else
		echo "Supermap already install"
	fi

	license=$supermap_path/support/SuperMap_License/Support
	echo $license

	cd $license && tar -xvf aksusbd_2.4.1-i386.tar

	regist_dir=$license/aksusbd-2.4.1-i386
	echo $regist_dir
	echo "123456"|sudo -s su - root -c"cd $regist_dir && ./dinst"

	if [ $? ]; then
		echo  "Supermap has been registed"
	else
	    echo  "Supermap regist has been failed"
		break
	fi

	sleep 3
	libmawt1=$supermap_path/support/objectsjava/bin/libmawt.so
	libmawt2=$supermap_path/support/jre/lib/amd64/headless/libmawt.so
	echo $supermap_path
	echo $libmawt1
	echo $libmawt2

	cp $libmawt1 $libmawt2

	if [ $? ]; then
	    echo "libmawt.so has been replaced"
	fi
	sleep 3
	echo "SuperMap install success"
	# sh $supermap_path/bin/startup.sh
}

installPathSelect(){
	echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
	echo "┠┈┈┈┈┈┈┈┈ INSTALL PATH CONFIG ┈┈┈┈┈┈┈┈┈┨"
	echo "┠┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┨"
	echo "┠┈┈┈┈┈ Please Select Install Path ┈┈┈┈┈┨"
	echo "┠┈┈ select [1~3] or input other path ┈┈┨"
	echo "┠┈┈┈┈┈┈┈┈ select [q] to exit ┈┈┈┈┈┈┈┈┈┈┨"
	echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
	echo "[1]/home/yuantiaotech/project/$system_name"
	echo "[2]/home/yuantiaotech                   "
	echo "[3]current path:$script_path            "
	echo "[q]exit                                 "
	echo "[*]input other path by yourself         "
	echo "┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅"

	read -p "please select [1~3] or input other path:" val
	case $val in
		1)	install_path=/home/yuantiaotech/project/$system_name
		;;
		2)  install_path=/home/yuantiaotech
		;; 
		3)  install_path=$script_path
		;;
		q)  exit 0
		;;
		*)	install_path=$val
		;;
	esac
}

portChange(){
	shutdow_port=$(($port_add+8005))
	http_port=$(($port_add+8081))
	redirect_port=$(($port_add+8443))
	ajp_port=$(($port_add+8009))
}

tomcatInstallSelect(){
	echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
	echo "┠┈┈┈┈┈┈┈┈┈┈┈ TOMCAT INSTALL ┈┈┈┈┈┈┈┈┈┈┈┨"
	echo "┠┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┨"
	echo "┠┈┈┈┈┈┈ Please Select System Name ┈┈┈┈┈┨"
	echo "┠┈┈ select [1~5] or input other name ┈┈┨"
	echo "┠┈┈┈┈┈┈┈┈ select [q] to exit ┈┈┈┈┈┈┈┈┈┈┨"
	echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
	echo "[1]index                                "
	echo "[2]monitor                              "
	echo "[3]guide                                "
	echo "[4]flowanalysis                         "
	echo "[5]toolsDownload                        "
	echo "[6]SuperMap                             "
	echo "[7]GeoLayer                             "
	echo "[8]GeoMap                               "
	echo "[q]exit                                 "
	echo "[*]input other name by yourself         "
	echo "┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅"

	read -p "please select [1~5] or input other name:" val
	case $val in
		1)	system_name=index
			port_add=0
			portChange
			installPathSelect
			tomcatInstall
		;;
		2)	system_name=monitor
			port_add=1
			portChange
			installPathSelect
			tomcatInstall
		;;
		3)	system_name=guide
			port_add=2
			portChange
			installPathSelect
			tomcatInstall
		;;
		4)  system_name=flowanalysis
			port_add=3
			portChange
			installPathSelect
			tomcatInstall
		;;
		5)  system_name=toolsDownload
			port_add=17
			portChange
			installPathSelect
			tomcatInstall
			toolsDownloadInstall
		;;
		6)  system_name=SuperMap
			installPathSelect
			supermapInstall
		;;
		7)  system_name=geoLayer
			port_add=7
			portChange
			installPathSelect
			tomcatInstall
			geoserverInstall
		;;
		8)  system_name=geoMap
			port_add=18
			portChange
			installPathSelect
			tomcatInstall
			geoserverInstall
		;;
		q)  exit 0
		;;
		*)	system_name=$val
			read -p "Please Input Shutdow Port (default:8005):" val2
			read -p "Please Input HTTP/1.1 Port (default:8081):" val3
			read -p "Please Input Redirect Port (default:8443):" val4
			read -p "Please Input AJP/1.3 Port (default:8009):" val5
			shutdow_port=$val2
			http_port=$val3
			redirect_port=$val4
			ajp_port=$val5
			installPathSelect
			tomcatInstall
		;;
	esac
}

dataserverInstall(){
	# check
	if [ ! -d $install_path ]; then
	    mkdir $install_path
	else
	    echo "$install_path already existd"
	fi
	
	dataserver_path=$install_path/dataserver_$system_name
	# copy dataserver to install path
	if [ ! -d $dataserver_path ]; then
	    cp -r /tmp/$dataserver_package/ $dataserver_path
	else
	    echo "$install_path/$system_name already install"
	fi

	# rename dataserver.jar
	mv $dataserver_path/datamonitorserver.jar $dataserver_path/dataserver_$system_name.jar

	# IP
	IP_old=`cat $dataserver_path/config/jdbc.properties|sed -n '3p'|sed 's#jdbc.url=jdbc:mysql://##g'|sed 's#:3306/indexmonitor##g'`
	IP_new=`ifconfig | grep "inet addr:"|head -n 1 | awk '{print $2}' | sed 's/addr://g'`
	echo "old IP is $IP_old and new IP is $IP_new"

	# configure jdbc.properties
	sed -i "s#\(jdbc.url=jdbc:mysql://\).*#\1$IP_new:3306/$database_name#g" $dataserver_path/config/jdbc.properties
	if [ $? -eq 0  ]; then
		echo "jdbc.properties in dataserver_$system_name configure success"
	else
		echo "jdbc.properties in dataserver_$system_name configure failed"
	fi

	# configure server.properties
	sed -i "s#server.port=....#server.port=$server_port#g" $dataserver_path/config/server.properties
	if [ $? -eq 0  ]; then
	    echo "server.properties in dataserver_$system_name configure success and server_port=$server_port"
	else
	    echo "server.properties in dataserver_$system_name configure failed"
	fi
	
	# configure start.sh
	if cat $dataserver_path/start.sh | grep dataserver_$system_name.jar >/dev/null
	then
		echo "start.sh already configured"	
	else
		sed -i "s/datamonitorserver.jar/dataserver_$system_name.jar/g" $dataserver_path/start.sh
		echo "start.sh configure success"
	fi

	sudo apt-get install dos2unix
	dos2unix dataserver_path/config/jdbc.properties

	echo "dataserver_$system_name install success"
}

dataserverInstallSelect(){
	echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
	echo "┠┈┈┈┈┈┈┈┈┈ DATASERVER INSTALL ┈┈┈┈┈┈┈┈┈┨"
	echo "┠┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┨"
	echo "┠┈┈┈┈┈┈ Please Select System Name ┈┈┈┈┈┨"
	echo "┠┈┈ select [1~3] or input other name ┈┈┨"
	echo "┠┈┈┈┈┈┈┈┈ select [q] to exit ┈┈┈┈┈┈┈┈┈┈┨"
	echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
	echo "[1]index                                "
	echo "[2]monitor                              "
	echo "[3]guide                                "
	echo "[q]exit                                 "
	echo "[*]input other name by yourself         "
	echo "┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅"

	read -p "please select [1~3] or input other name:" val
	case $val in
		1)	system_name=index
			database_name=indexmonitor
			server_port=4370
			installPathSelect
			dataserverInstall
		;;
		2)	system_name=monitor
			database_name=monitor
			server_port=4371
			installPathSelect
			dataserverInstall
		;;
		3)	system_name=guide
			database_name=guide
			server_port=4372
			installPathSelect
			dataserverInstall
		;;
		q)  exit 0
		;;
		*)	system_name=$val
			read -p "Please Input Database Name:" val2
			database_name=$val2
			read -p "Please Input Server Port(default:4370):" val3
			server_port=$val3
			installPathSelect
			dataserverInstall
		;;
	esac
}

addUser(){
	# 创建yuantiaotech用户
	echo "123456"|sudo -S adduser $user_name
	echo "123456"|sudo -S passwd $user_name --stdin &>/dev/null
	echo "123456"|sudo -S chmod -v u+w /etc/sudoers
	echo "123456"|sudo -S sed -i '$a'$(echo $user_name)'  ALL=(ALL)       ALL' /etc/sudoers
	echo "123456"|sudo -S chmod -v u-w /etc/sudoers
}

addUserSelect(){
	echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
	echo "┠┈┈┈┈┈┈┈┈┈┈┈┈┈┈ ADD USER ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┨"
	echo "┠┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┨"
	echo "┠┈┈┈┈┈┈ Please Select USER Name ┈┈┈┈┈┈┈┨"
	echo "┠┈┈┈ select [1] or input other name ┈┈┈┨"
	echo "┠┈┈┈┈┈┈┈┈ select [q] to exit ┈┈┈┈┈┈┈┈┈┈┨"
	echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
	echo "[1]yuantiaotech                         "
	echo "[q]exit                                 "
	echo "[*]input other name by yourself         "
	echo "┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅"

	read -p "please select [1] or input other name:" val
	case $val in
		1)	user_name=yuantiaotech
		;;
		q)  exit 0
		;;
		*)	user_name=$val
		;;
	esac
	addUser
}

CentOSJDKInstall(){
	# jdk安装
	tar -zxvf /tmp/jdk-7u80-linux-x64.tar.gz -C /home/yuantiaotech/amoy
	echo "123456"|sudo -S sed -i '$aexport JAVA_HOME=/home/yuantiaotech/amoy/jdk1.7.0_80' /etc/profile
	echo "123456"|sudo -S sed -i '$aexport JRE_HOME=${JAVA_HOME}/jre' /etc/profile
	echo "123456"|sudo -S sed -i '$aexport CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib::$CATALINA_HOME/lib' /etc/profile
	echo "123456"|sudo -S sed -i '$aexport CLASSPATH=$CLASSPATH:.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib' /etc/profile
	echo "123456"|sudo -S sed -i '$aPATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin' /etc/profile
	# 生效配置
	source /etc/profile

	# 修改当前用户的环境变量
	echo "123456"|sudo -S sed -i '$aexport JAVA_HOME=/home/yuantiaotech/amoy/jdk1.7.0_80' /home/yuantiaotech/.bashrc
	echo "123456"|sudo -S sed -i '$aexport JRE_HOME=${JAVA_HOME}/jre' /home/yuantiaotech/.bashrc
	echo "123456"|sudo -S sed -i '$aexport CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib::$CATALINA_HOME/lib' /home/yuantiaotech/.bashrc
	echo "123456"|sudo -S sed -i '$aexport CLASSPATH=$CLASSPATH:.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib' /home/yuantiaotech/.bashrc
	echo "123456"|sudo -S sed -i '$aPATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin' /home/yuantiaotech/.bashrc

	source /home/yuantiaotech/.bashrc
	echo "JAVA_HOME=/home/yuantiaotech/amoy/jdk1.7.0_80" >> /etc/environment
}

UbuntuJDKInstall(){
	tar -zxvf /tmp/jdk-7u80-linux-x64.tar.gz -C /home/yuantiaotech/amoy
	echo "123456"|sudo -S sed -i '$aexport JAVA_HOME=/home/yuantiaotech/amoy/jdk1.7.0_80' /etc/profile
	echo "123456"|sudo -S sed -i '$aexport JRE_HOME=${JAVA_HOME}/jre' /etc/profile
	echo "123456"|sudo -S sed -i '$aexport CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib::$CATALINA_HOME/lib' /etc/profile
	echo "123456"|sudo -S sed -i '$aexport CLASSPATH=$CLASSPATH:.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib' /etc/profile
	echo "123456"|sudo -S sed -i '$aPATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin' /etc/profile
	# 生效配置
	source /etc/profile
	sudo update-alternatives --install /usr/bin/java java /home/yuantiaotech/amoy/jdk1.7.0_80/jre/bin/java 300
	sudo update-alternatives --install /usr/bin/javac javac /home/yuantiaotech/amoy/jdk1.7.0_80/bin/javac 300
	sudo update-alternatives --config java
	sudo update-alternatives --config javac

}

JDKInstallSelect(){
	echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
	echo "┠┈┈┈┈┈┈┈┈┈┈┈┈ JDK INSTALL ┈┈┈┈┈┈┈┈┈┈┈┈┈┨"
	echo "┠┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┨"
	echo "┠┈┈┈┈┈┈┈ Please Select SYSTEM ┈┈┈┈┈┈┈┈┈┨"
	echo "┠┈┈┈┈┈┈┈┈┈ select [1] or [2] ┈┈┈┈┈┈┈┈┈┈┨"
	echo "┠┈┈┈┈┈┈┈┈ select [q] to exit ┈┈┈┈┈┈┈┈┈┈┨"
	echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
	echo "[1]CentOS                               "
	echo "[2]Ubuntu                               "
	echo "[q]exit                                 "
	echo "┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅"

	read -p "please select [1] or input other name:" val
	case $val in
		1)	CentOSJDKInstall
		;;
		2)	UbuntuJDKInstall
		;;
		q)  exit 0
		;;
	esac
}

SupervisorInstall(){
	# 安装supervisor
	# 解压安装
	tar -zxvf /tmp/meld3-1.0.2.tar.gz -C /home/yuantiaotech/amoy
	python /home/yuantiaotech/amoy/meld3-1.0.2/setup.py install
	tar -zxvf /tmp/supervisor-3.3.1.tar.gz -C /home/yuantiaotech/amoy
	python /home/yuantiaotech/amoy/supervisor-3.3.1/setup.py install
	# 创建conf.d
	mkdir -p /etc/supervisor/conf.d
	# 初始化supervisord.conf
	echo_supervisord_conf > /etc/supervisor/supervisord.conf
	echo "123456"|sudo -S sed -i '$a[include]' /etc/supervisor/supervisord.conf
	echo "123456"|sudo -S sed -i '$afiles = /etc/supervisor/conf.d/*.conf' /etc/supervisor/supervisord.conf
	mv supervisord /etc/init.d/
	chmod 755 /etc/init.d/supervisord
	# 开机自启
	chkconfig --add supervisord
	chkconfig supervisord on
}

allInstallMenu(){
	echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
	echo "┣━━━━━━━━━━━━━━━━ MENU ━━━━━━━━━━━━━━━━┫"
	echo "┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫"
	echo "┣━━━━━━ Select [1~3] To Install ━━━━━━━┫"
	echo "┣━━━━━━━━ Select [q] To Exit ━━━━━━━━━━┫"
	echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
	echo "[1]tomcat                               "
	echo "[2]dataserver                           "
	echo "[3]add User                             "
	echo "[4]JDK7u80                              "
	echo "[5]Supervisor                           "
	echo "[q]exit                                 "
	echo "┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅"

	read -p "Please Select [1~2]:" val
	case $val in
		1)	tomcatInstallSelect
 		;;
		2)	dataserverInstallSelect
		;;
		3)	addUserSelect
		;;
		4)  JDKInstallSelect
		;;
		5)	SupervisorInstall
		;;
		q)  exit 0
		;;
		*)  echo "脑抽啊！就[1][2][3]三个选项好吗！"
		;;
	esac
}
allInstallMenu