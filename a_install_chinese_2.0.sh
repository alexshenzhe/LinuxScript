#!/bin/bash

# 文 件 名 : a_install_chinese2.0.sh
# 作    者 : 沈喆
# 创建时间 : 2017/04/13
# 版 本 号 : 2.1.2
# 更新时间 : 2018/02/25
# 描    述 : 这个脚本用于部署态势2.0过程中安装JDK、Supermap、Supervisor、MySQL、Oracle、Tomcat、toolsDownload、ActiveMQ，后续增不增加就看我心情了。
#			 脚本默认会配置tomcat的默认内存(512~1024m)及报表，新增加了创建或删除linux用户以及关闭防火墙及SELINUX，自动将ActiveMQ添加到系统服务开机自启进行管理，
#			 根据提示操作即可。
#			 建议在yauntiaotech用户下运行脚本。
# 依 赖 包 : JDK        : jdk-7u80-linux-x64.tar.gz
#			 Supervisor : supervisor-3.3.1.tar.gz、meld3-1.0.2.tar.gz、supervisord
#			 MySQL      : MySQL-5.6.36-1.el6.x86_64.rpm-bundle.tar
#			 Tomcat     : apache-tomcat-7.0.63.tar.gz
#			 Supermap   : supermap_iserver_7.1.2_linux64.tar.gz
#			 Oracle     : linux.x64_11gR2_database_1of2.zip、linux.x64_11gR2_database_2of2.zip、centos6.8_oracle11grpm.tar.gz
#			 ActiveMQ   : apache-activemq-5.14.2-bin.tar.gz
#
#			 以上安装包可以从ftp://192.168.0.150/项目部文档/技术支持/部署常用软件/脚本/a_install文件夹下获取(使用support/123456登录)。

# 更新说明 : 1. 增加CentOS下supermap依赖包安装；
#			 2. 修正Mysql安装后my.cnf可能无效的问题；
#			 3. 由于CDH安装需要，MySQL配置时会创建一个scm用户。

#----------------------------------------------------------------------------------------------------------------------------------------------------
# 系统变量
system_name=0 # 系统名称 例如 index、monitor、guide...
script_path=$(cd "$(dirname "$0")"; pwd) # 当前脚本路径
shutdow_port=8005 # tomcat 端口
http_port=8081 # tomcat 端口
redirect_port=8443 # tomcat 端口
ajp_port=8009 # tomcat 端口
tomcat_install_path=0 # tomcat安装路径，用户选择或输入
tomcat_file_path=0 # tomcat 文件夹路径
user_name=yuantiaotech # 默认需要创建的用户名
all_packages_path=/tmp # 默认安装包放置路径，所有安装包都会到这个路径下去读取
IP_address=`ifconfig | grep "inet addr:"|head -n 1 | awk '{print $2}' | sed 's/addr://g'` # 当前服务器IP地址


#==================================================================== tomcat 安装 ====================================================================
tomcatInstall(){
	# tomcat 安装包名
	tomcatFileName=apache-tomcat-7.0.63
	# tomcat 安装路径，用户自定义路径
	tomcat_file_path=$tomcat_install_path/tomcat_$system_name
	# 检查安装路径
	checkInstallPath $tomcat_install_path

	# 检查压缩包是否解压
	if [ ! -d $all_packages_path/$tomcatFileName ]; then
		if [ ! -f $all_packages_path/$tomcatFileName.tar.gz ]; then
			echo -e "\033[31m错误：$tomcatFileName.tar.gz压缩包不存在，先将压缩包拷贝至$all_packages_path路径下！\033[0m"
			return
		else
			tar -zxvf $all_packages_path/$tomcatFileName.tar.gz -C $all_packages_path
			if [ $? -eq 0 ]; then
				echo -e "\033[32m$tomcatFileName.tar.gz 解压成功\033[0m"
			else
				echo -e "\033[31m$tomcatFileName.tar.gz 解压失败\033[0m"
				return
			fi
			sleep 3
		fi
	else
		echo -e "\033[32m$tomcatFileName 压缩包已经解压\033[0m"
	fi

	if [ ! -d $tomcat_file_path ]; then
		cp -r $all_packages_path/$tomcatFileName $tomcat_file_path  # 拷贝并重命名
	else
		echo -e "\033[32m$tomcat_file_path 已经存在\033[0m"
	fi

	# 用于计数，判断安装是否成功
	count=0
	# 配置 /etc/profile 的 TOMCAT_HOME
	if cat /etc/profile | grep CATALINA_HOME_$system_name >/dev/null
		then
		let count+=1
	    echo -e "\033[32m/etc/profile TOMCAT_HOME_$system_name 已经配置\033[0m"	
	else
	    echo -e "\033[32m/etc/profile 中配置 tomcat_$system_name"
		echo "123456"|sudo -S sed -i '$a##########'$(echo $system_name)' tomcat##########' /etc/profile
		echo "123456"|sudo -S sed -i '$aTOMCAT_HOME_'$(echo $system_name)'='$(echo $tomcat_file_path)'' /etc/profile
		echo "123456"|sudo -S sed -i '$aCATALINA_HOME_'$(echo $system_name)'='$(echo $tomcat_file_path)'' /etc/profile
		echo "123456"|sudo -S sed -i '$aCATALINA_BASE_'$(echo $system_name)'='$(echo $tomcat_file_path)'' /etc/profile
		echo "123456"|sudo -S sed -i '$aexport TOMCAT_HOME_'$(echo $system_name)'  CATALINA_HOME_'$(echo $system_name)'  CATALINA_BASE_'$(echo $system_name)'' /etc/profile
		echo "123456"|sudo -S sed -i '$a##########'$(echo $system_name)' tomcat##########' /etc/profile

		if cat /etc/profile | grep CATALINA_HOME_$system_name >/dev/null
			then
			let count+=1
			echo -e "\033[32m/etc/profile 配置 TOMCAT_HOME&TOMCAT_BASE 成功\033[0m"
		else
			echo -e "\033[31m/etc/profile 配置 TOMCAT_HOME&TOMCAT_BASE 失败\033[0m"
		fi
	fi
	sleep 1

	# 配置 $tomcat_file_path/bin/catalina.sh 的 CATALINA_HOME 
	if cat $tomcat_file_path/bin/catalina.sh | grep CATALINA_HOME_$system_name >/dev/null 
		then
		let count+=1
	    echo -e "\033[32m$tomcat_file_path/bin/catalina.sh TOMCAT_HOME_$system_name 已经配置\033[0m"
	else
		sed -i "s/CATALINA_HOME/CATALINA_HOME_$system_name/g" $tomcat_file_path/bin/catalina.sh
		if cat $tomcat_file_path/bin/catalina.sh | grep CATALINA_HOME_$system_name >/dev/null
			then
			let count+=1
			echo -e "\033[32m$tomcat_file_path/bin/catalina.sh CATALINA_HOME_$system_name 配置成功\033[0m"
		else
			echo -e "\033[31m$tomcat_file_path/bin/catalina.sh CATALINA_HOME_$system_name 配置失败\033[0m"
		fi
	fi
	sleep 1

	# 配置 $tomcat_file_path/bin/catalina.sh 的 CATALINA_BASE 
	if cat $tomcat_file_path/bin/catalina.sh | grep CATALINA_BASE_$system_name >/dev/null 
		then
		let count+=1
	    echo -e "\033[32m$tomcat_file_path/bin/catalina.sh TOMCAT_BASE_$system_name 已经配置\033[0m"
	else
		sed -i "s/CATALINA_BASE/CATALINA_BASE_$system_name/g" $tomcat_file_path/bin/catalina.sh
		if cat $tomcat_file_path/bin/catalina.sh | grep CATALINA_BASE_$system_name >/dev/null
			then
			let count+=1
			echo -e "\033[32m$tomcat_file_path/bin/catalina.sh CATALINA_BASE_$system_name 配置成功\033[0m"
		else
			echo -e "\033[31m$tomcat_file_path/bin/catalina.sh CATALINA_BASE_$system_name 配置失败\033[0m"
		fi
	fi
	sleep 1

	# 配置tomcat默认内存大小以及报表编码等
	sed -i "1 aJAVA_OPTS='-server -Xms512m -Xmx1024m -XX:PermSize=64m -XX:MaxPermSize=256m -Djava.awt.headless=true -DFile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8'" $tomcat_file_path/bin/catalina.sh
	sed -i "1 aexport LC_ALL=\"zh_CN.UTF-8\"" $tomcat_file_path/bin/catalina.sh

	if [ $? -eq 0  ]; then
		let count+=1
		echo -e "\033[32mtomcat_$system_name内存、报表配置成功\033[0m"
	else
		echo -e "\033[31mtomcat_$system_name内存、报表配置失败\033[0m"
	fi
	sleep 1
	
	# tomcat 端口配置
	sed -i "s/8005/$shutdow_port/g" $tomcat_file_path/conf/server.xml
	sed -i "s/8081/$http_port/g" $tomcat_file_path/conf/server.xml
	sed -i "s/8443/$redirect_port/g" $tomcat_file_path/conf/server.xml
	sed -i "s/8009/$ajp_port/g" $tomcat_file_path/conf/server.xml

	if [ $? -eq 0  ]; then
		let count+=1
		echo -e "\033[32mtomcat_$system_name 端口配置成功\033[0m"

		echo -e "\033[32mShutdown Port:$shutdow_port\033[0m"
		echo -e "\033[32mHTTP/1.1 Port:$http_port\033[0m"
		echo -e "\033[32mRedirect Port:$redirect_port\033[0m"
		echo -e "\033[32mAJP/1.3 Port:$ajp_port\033[0m"
	else
		echo -e "\033[31mtomcat_$system_name 端口配置失败\033[0m"
	fi

	if [ "$count" == 5 ]; then
		echo -e "\033[32mtomcat_$system_name --------------------------- [安装成功]\033[0m"
	elif [ "$count" != 5 ]; then
		echo -e "\033[31mtomcat_$system_name --------------------------- [安装失败]\033[0m"
		return
	fi

	if [ "$system_name" == "toolsDownload" ]; then
		toolsDownloadInstall
	elif [ "$system_name" == "geoLayer" ] || [ "$system_name" == "geoMap" ]; then
		geoserverInstall
	fi
}

#==================================================================== toolsDownload安装 ====================================================================
toolsDownloadInstall(){
	if [ ! -d $all_packages_path/toolsDownload ]; then
		echo -e "\033[31m错误：toolsDownload文件夹不存在，先将文件夹拷贝至$all_packages_path路径下！\033[0m"
		return
	else
		#拷贝 web.xml&favicon.ico&toolsDownload 到 tomcat
		cp $all_packages_path/toolsDownload/web.xml $tomcat_file_path/conf/
		cp $all_packages_path/toolsDownload/favicon.ico $tomcat_file_path/webapps/ROOT/
		cp -r $all_packages_path/toolsDownload/toolsDownload $tomcat_file_path/webapps/
	fi

	if [ $? -eq 0  ]; then
		echo -e "\033[32mtomcat_$system_name 数据拷贝成功\033[0m"
	else
		echo -e "\033[31mtomcat_$system_name 数据拷贝失败\033[0m"
	fi
}

#==================================================================== geoserver安装 ====================================================================
geoserverInstall(){
	if [ "$system_name" == "geoMap" ]; then
		#拷贝 geoserver.war 到 tomcat
		if [ ! -f $all_packages_path/geoserver.war ]; then
			echo -e "\033[31m错误：geoserver.war压缩包不存在，先将压缩包拷贝至$all_packages_path路径下！\033[0m"
			return
		else
			cp -r $all_packages_path/geoserver.war $tomcat_file_path/webapps/
		fi
	elif [ "$system_name" == "geoLayer" ]; then
		#拷贝 geoserver 到 tomcat
		if [ ! -d $all_packages_path/geoserver ]; then
			echo -e "\033[31m错误：geoserver文件夹不存在，先将文件夹拷贝至$all_packages_path路径下！\033[0m"
			return
		else
			cp -r $all_packages_path/geoserver $tomcat_file_path/webapps/
		fi
	fi

	if [ $? -eq 0  ]; then
		echo -e "\033[32mtomcat_$system_name 数据拷贝成功\033[0m"
	else
		echo -e "\033[31mtomcat_$system_name 数据拷贝失败\033[0m"
	fi
}

#==================================================================== 超图安装 ====================================================================
supermapInstall(){
	# supermap 安装路径
	supermapInstallPath=/home/yuantiaotech
	# supermap 压缩包名
	supermapPackageName=supermap_iserver_7.1.2_linux64.tar.gz
	# supermap 文件夹名
	supermapFileName=SuperMapiServer7C
	# supermap 依赖包名
	DependentPackageName=Centos-offline-supermap.tar.gz
	# supermap 依赖包文件夹名
	DependentFileName=offline-supermap
	# supermap 文件夹路径
	supermapFilePath=$supermapInstallPath/$supermapFileName
	# 用于计数，判断安装是否成功
	count=0

	# 解压安装依赖包
	if [ ! -d $all_packages_path/$DependentFileName ]; then
		if [ ! -f $all_packages_path/$DependentPackageName ]; then
			echo -e "\033[31m错误：$DependentPackageName 压缩包不存在，先将压缩包拷贝至$all_packages_path路径下！\033[0m"
			return
		else
			tar -zxvf $all_packages_path/$DependentPackageName -C $all_packages_path
			sleep 2

			# 安装依赖包
			echo "123456"|sudo -S rpm -ivh --force --nodeps $all_packages_path/$DependentFileName/*.rpm

			if [ $? -eq 0 ]; then
				let count+=1
				echo -e "\033[32mSuperMap 依赖环境安装成功\033[0m"
			else
				echo -e "\033[31mSuperMap 依赖环境安装失败\033[0m"
				return
			fi
		fi
	fi

	# 安装 supermap
	if [ ! -d $supermapFilePath ]; then
		if [ ! -f $all_packages_path/$supermapPackageName ]; then
			echo -e "\033[31m错误：$supermapPackageName压缩包不存在，先将压缩包拷贝至$all_packages_path路径下！\033[0m"
			return
		else
			tar -zxvf $all_packages_path/$supermapPackageName -C $supermapInstallPath
			sleep 50
			if [ $? -eq 0 ]; then
				let count+=1
				echo -e "\033[32m$supermapPackageName 解压成功\033[0m"
			else
				echo -e "\033[31m$supermapPackageName 解压失败\033[0m"
				return
			fi
		fi
	else
		let count+=1
		echo -e "\033[32mSupermap 已经存在\033[0m"
	fi

	license=$supermapFilePath/support/SuperMap_License/Support
	echo $license

	cd $license && tar -xvf aksusbd_2.4.1-i386.tar

	regist_dir=$license/aksusbd-2.4.1-i386
	echo $regist_dir
	echo "123456"|sudo -S su - root -c "cd $regist_dir && ./dinst"

	if [ $? ]; then
		let count+=1
		echo -e "\033[32mSupermap 注册成功\033[0m"
	else
	    echo -e "\033[31mSupermap 注册失败\033[0m"
		break
	fi

	libmawt1=$supermapFilePath/support/objectsjava/bin/libmawt.so
	libmawt2=$supermapFilePath/support/jre/lib/amd64/headless/libmawt.so
	echo $supermapFilePath
	echo $libmawt1
	echo $libmawt2

	cp $libmawt1 $libmawt2

	if [ $? ]; then
		let count+=1
	    echo -e "\033[32mlibmawt.so 替换成功\033[0m"
	fi
	sleep 3

	if [ "$count" == 4 ]; then
		echo -e "\033[32mSuperMap --------------------------- [安装成功]\033[0m"
	elif [ "$count" != 4 ]; then
		echo -e "\033[31mSuperMap --------------------------- [安装失败]\033[0m"
		return
	fi
	sh $supermapFilePath/bin/startup.sh
}

#==================================================================== 安装路径选择列表 ====================================================================
installPathSelect(){
	echo -e "\033[32m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\033[0m"
	echo -e "\033[32m┠┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ 选择安装路径 ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┨\033[0m"
	echo -e "\033[32m┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫\033[0m"
	echo -e "\033[32m┃ [1]/home/yuantiaotech                      ┃\033[0m"
	echo -e "\033[32m┃ [2]当前脚本路径：$script_path			   \033[0m"
	echo -e "\033[32m┃ [B]返回主菜单                  [Q]退出安装 ┃\033[0m"
	echo -e "\033[32m┃                                            ┃\033[0m"
	echo -e "\033[32m┃ *支持直接输入，请确保路径存在！            ┃\033[0m"
	echo -e "\033[32m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\033[0m"

	read -p "选择安装路径编号或直接输入:" val
	case $val in
		1)  tomcat_install_path=/home/yuantiaotech
		;; 
		2)  tomcat_install_path=$script_path
		;;
		B|b)  allInstallMenu
		;;
		Q|q)  exit 0
		;;
		*)	tomcat_install_path=$val
		;;
	esac
}

#==================================================================== 端口变化 ====================================================================
portChange(){
	shutdow_port=$(($1+8005))
	http_port=$(($1+8081))
	redirect_port=$(($1+8443))
	ajp_port=$(($1+8009))
}

#==================================================================== tomcat名称选择 ====================================================================
tomcatInstallSelect(){
	echo -e "\033[32m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\033[0m"
	echo -e "\033[32m┠┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ TOMCAT 安装 ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┨\033[0m"
	echo -e "\033[32m┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫\033[0m"
	echo -e "\033[32m┃ [1]GeoMap                  [2]GeoLayer     ┃\033[0m"
	echo -e "\033[32m┃ [3]toolsDownload           [4]SuperMap     ┃\033[0m"
	echo -e "\033[32m┃ [B]返回主菜单              [Q]退出安装     ┃\033[0m"
	echo -e "\033[32m┃                                            ┃\033[0m"	
	echo -e "\033[32m┃ *支持直接输入                              ┃\033[0m"
	echo -e "\033[32m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\033[0m"

	read -p "选择安装的系统名称编号或直接输入:" val
	case $val in
		1)  system_name=geoMap
			portChange 18
			installPathSelect
			tomcatInstall
		;;
		2)  system_name=geoLayer
			portChange 7
			installPathSelect
			tomcatInstall
		;;
		3)  system_name=toolsDownload
			portChange 17
			installPathSelect
			tomcatInstall
		;;
		4)  system_name=SuperMap
			supermapInstall
		;;
		B|b)  allInstallMenu
		;;
		Q|q)  exit 0
		;;
		*)	system_name=$val
			read -p "请输入 Shutdow 端口(默认:8005):" val2
			read -p "请输入 HTTP/1.1 端口(默认:8081):" val3
			read -p "请输入 Redirect 端口(默认:8443):" val4
			read -p "请输入 AJP/1.3 端口(默认:8009):" val5
			shutdow_port=$val2
			http_port=$val3
			redirect_port=$val4
			ajp_port=$val5
			installPathSelect
			tomcatInstall
		;;
	esac
}

#==================================================================== 创建、删除用户选择 ==================================================================== 
UserSelect(){
	echo -e "\033[32m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\033[0m"
	echo -e "\033[32m┠┈┈┈┈┈┈┈┈┈┈┈┈┈ 选择创建/删除用户 ┈┈┈┈┈┈┈┈┈┈┈┈┨\033[0m"
	echo -e "\033[32m┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫\033[0m"
	echo -e "\033[32m┃ [1]创建用户                    [2]删除用户 ┃\033[0m"
	echo -e "\033[32m┃ [B]返回主菜单                  [Q]退出安装 ┃\033[0m"
	echo -e "\033[32m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\033[0m"

	read -p "请选择创建或者删除用户:" val
	case $val in
		1)	UserNameSelect
			addUser
		;;
		2)	UserNameSelect
			deleteUser
		;;
		B|b)  allInstallMenu
		;;
		Q|q)  exit 0
		;;
		*)  echo -e "\033[31m输入有误\033[0m"
			return
		;;
	esac
}

#==================================================================== 创建用户 ====================================================================
addUser(){
	# 创建yuantiaotech用户，并添加sudo权限，默认密码123456
	egrep "^$user_name" /etc/passwd >& /dev/null
	if [ $? -ne 0 ]  
		then  
	    echo "123456"|sudo -S adduser $user_name 
	    echo "123456"|sudo -S passwd $user_name --stdin &>/dev/null
		echo "123456"|sudo -S chmod -v u+w /etc/sudoers
		echo "123456"|sudo -S sed -i '$a'$(echo $user_name)'  ALL=(ALL)       ALL' /etc/sudoers
		echo "123456"|sudo -S chmod -v u-w /etc/sudoers 
		
		if [ $? -eq 0  ]; then
			echo -e "\033[32m用户: $user_name --------------------------- [创建成功]\033[0m"
			echo -e "\033[32m已经切换到 $user_name 用户\033[0m"
			su - $user_name
		else
			echo -e "\033[31m用户: $user_name --------------------------- [创建失败]\033[0m"
		fi
	else
		echo -e "\033[32m用户: $user_name 已经存在\033[0m"
	fi
}

#==================================================================== 删除用户 ====================================================================
deleteUser(){
	egrep "^$user_name" /etc/passwd >& /dev/null
	if [ $? -ne 0 ]  
		then
		echo -e "\033[32m用户: $user_name 不存在\033[0m" 
	else
		read -p "你正在删除用户：$user_name，是否确定[Y/N]:" val
		case $val in
			Y|y)  echo "123456"|sudo -S userdel -r $user_name
				  if [ $? -eq 0  ]; then
					echo "123456"|sudo -S chmod -v u+w /etc/sudoers
				  	echo "123456"|sudo -S sed -i -e "/$user_name/d" /etc/sudoers
				  	echo "123456"|sudo -S chmod -v u-w /etc/sudoers
				  	echo -e "\033[32m用户: $user_name --------------------------- [删除成功]\033[0m"
				  else
				  	echo -e "\033[31m用户: $user_name --------------------------- [删除失败]\033[0m"
				  	return
				  fi
			;;
			N|n)  allInstallMenu
			;;
			*)	echo -e "\033[31m输入有误\033[0m"
				return
			;;
		esac
	fi 
}

#==================================================================== 用户名称选择 ====================================================================
UserNameSelect(){
	echo -e "\033[32m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\033[0m"
	echo -e "\033[32m┠┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ 选择用户名称 ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┨\033[0m"
	echo -e "\033[32m┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫\033[0m"
	echo -e "\033[32m┃ [1]yuantiaotech                            ┃\033[0m"
	echo -e "\033[32m┃ [B]返回主菜单                  [Q]退出安装 ┃\033[0m"
	echo -e "\033[32m┃                                            ┃\033[0m"	
	echo -e "\033[32m┃ *支持直接输入                              ┃\033[0m"
	echo -e "\033[32m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\033[0m"

	read -p "选择创建的用户名称编号或直接输入:" val
	case $val in
		1)	user_name=yuantiaotech
		;;
		B|b)  allInstallMenu
		;;
		Q|q)  exit 0
		;;
		*)	user_name=$val
		;;
	esac
}

#==================================================================== JDK安装 ====================================================================
JDKInstall(){
	# JDK 安装路径
	JDKInstallPath=/home/yuantiaotech
	# JDK 安装包名称
	JDKPackageName=jdk-7u80-linux-x64.tar.gz
	# JDK 文件夹名称
	JDKFileName=jdk1.7.0_80
	# JDK 文件夹路径
	JDKFilePath=$JDKInstallPath/$JDKFileName

	# 检查amoy路径
	checkInstallPath $JDKInstallPath

	# 用于计数，判断安装是否成功
	count=0
	if [ ! -d $JDKFilePath ]; then
		if [ ! -f $all_packages_path/$JDKPackageName ]; then
			echo -e "\033[31m错误：$JDKPackageName 压缩包不存在，先将压缩包拷贝至$all_packages_path路径下！\033[0m"
			return
		else
			tar -zxvf $all_packages_path/$JDKPackageName -C $JDKInstallPath
			sleep 3
			if [ $? -eq 0 ]; then
				let count+=1
				echo -e "\033[32m$JDKPackageName 解压成功\033[0m"
			else
				echo -e "\033[31m$JDKPackageName 解压失败\033[0m"
				return
			fi
		fi
	else
		let count+=1
		echo -e "\033[32m$JDKFileName 已经存在\033[0m"
	fi

	# 卸载旧版本
	echo -e "\033[31m开始卸载旧版本...请等待...\033[0m"
	echo "123456"|sudo -S rpm -qa | grep java | xargs rpm -e --nodeps
	# 检查卸载情况
	javaOld=`rpm -qa | grep java`
	if [ "$javaOld" != "" ]; then
		echo "123456"|sudo -S rpm -e --nodeps tzdata-java-2016c-1.el6.noarch
		echo "123456"|sudo -S rpm -e --nodeps java-1.6.0-openjdk-1.6.0.38-1.13.10.4.el6.x86_64
		echo "123456"|sudo -S rpm -e --nodeps java-1.7.0-openjdk-1.7.0.99-2.6.5.1.el6.x86_64
	fi
	
	if cat /etc/profile | grep JAVA_HOME >/dev/null
		then
		echo -e "\033[32mJDK 系统环境变量已经存在\033[0m"
	else
		# 修改系统环境变量
		echo "123456"|sudo -S sed -i '$a########### JAVA Environment #############' /etc/profile
		echo "123456"|sudo -S sed -i '$aexport JAVA_HOME='$(echo $JDKFilePath)'' /etc/profile
		echo "123456"|sudo -S sed -i '$aexport JRE_HOME=$JAVA_HOME/jre' /etc/profile
		echo "123456"|sudo -S sed -i '$aexport CLASSPATH=./:$JAVA_HOME/lib:$JAVA_HOME/jre/lib' /etc/profile
		echo "123456"|sudo -S sed -i '$aexport PATH=$PATH:$JAVA_HOME/bin' /etc/profile
		# 生效配置
		source /etc/profile
	fi

	if cat /home/yuantiaotech/.bashrc | grep JAVA_HOME >/dev/null
		then
		echo -e "\033[32mJDK 用户环境变量已经存在\033[0m"
	else
		# 修改用户环境变量
		echo "123456"|sudo -S sed -i '$a########### JAVA Environment #############' /home/yuantiaotech/.bashrc
		echo "123456"|sudo -S sed -i '$aexport JAVA_HOME='$(echo $JDKFilePath)'' /home/yuantiaotech/.bashrc
		echo "123456"|sudo -S sed -i '$aexport JRE_HOME=$JAVA_HOME/jre' /home/yuantiaotech/.bashrc
		echo "123456"|sudo -S sed -i '$aexport CLASSPATH=./:$JAVA_HOME/lib:$JAVA_HOME/jre/lib' /home/yuantiaotech/.bashrc
		echo "123456"|sudo -S sed -i '$aexport PATH=$PATH:$JAVA_HOME/bin' /home/yuantiaotech/.bashrc
		# 生效配置
		source /home/yuantiaotech/.bashrc
		echo "123456"|sudo -S su - root -c "echo "JAVA_HOME=$JDKFilePath" >> /etc/environment"
		source /etc/environment
	fi
	
	if [ $? -eq 0 ]; then
		let count+=1
		echo -e "\033[32mJDK 环境变量配置成功\033[0m"
	else
		echo -e "\033[31mJDK 环境变量配置失败\033[0m"
	fi

	# 添加JDK软链接，CDH安装时候需要
	if [ ! -d /usr/java ]; then
		echo "123456"|sudo -S mkdir /usr/java
	fi
	echo "123456"|sudo -S ln -s $JDKFilePath/ /usr/java/
	echo "123456"|sudo -S mv /usr/java/$JDKFileName /usr/java/jdk1.7

	if [ "$count" == 2 ]; then
		echo -e "\033[32mJDK --------------------------- [安装成功]\033[0m"
		echo -e "\033[32mJDK 版本信息：\033[0m"
		java -version
	elif [ "$count" != 2 ]; then
		echo -e "\033[31mJDK --------------------------- [安装失败]\033[0m"
	fi
}


#==================================================================== Supervisor安装 ====================================================================
SupervisorInstall(){
	# 安装路径
	installPath=/home/yuantiaotech/supervisor
	# meld 安装包名称
	meldPackageName=meld3-1.0.2.tar.gz
	# meld 文件夹名称
	meldFileName=meld3-1.0.2
	# supervisor 安装包名称
	supervisorPackageName=supervisor-3.3.1.tar.gz
	# supervisor 文件夹名称
	supervisorFileName=supervisor-3.3.1

	# 检查amoy路径
	checkInstallPath $installPath

	# 检查java环境
	java -version
	if [ "$JAVA_HOME" == "" ]; then
		echo -e "\033[31mJAVA_HOME环境有误，请确认后再安装Supervisor。\033[0m"
		return
	fi

	# 用于计数，判断安装是否成功
	count=0
	# 解压
	if [ ! -d $installPath/$meldFileName ]; then
		if [ ! -f $all_packages_path/$meldPackageName ]; then
			echo -e "\033[31m错误：$meldPackageName压缩包不存在，先将压缩包拷贝至$all_packages_path路径下！\033[0m"
			return
		else
			tar -zxvf $all_packages_path/$meldPackageName -C $installPath
			if [ $? -eq 0 ]; then
				let count+=1
				echo -e "\033[32m$meldPackageName 解压成功\033[0m"
			else
				echo -e "\033[31m$meldPackageName 解压失败\033[0m"
				return
			fi
			sleep 3
		fi
	else
		let count+=1
		echo -e "\033[32m$meldFileName 已经存在\033[0m"
	fi

	if [ ! -d $installPath/$supervisorFileName ]; then
		if [ ! -f $all_packages_path/$supervisorPackageName ]; then
			echo -e "\033[31m错误：$supervisorPackageName压缩包不存在，先将压缩包拷贝至$all_packages_path路径下！\033[0m"
			return
		else
			tar -zxvf $all_packages_path/$supervisorPackageName -C $installPath
			if [ $? -eq 0 ]; then
				let count+=1
				echo -e "\033[32m$supervisorPackageName 解压成功\033[0m"
			else
				echo -e "\033[31m$supervisorPackageName 解压失败\033[0m"
				return
			fi
			sleep 3
		fi
	else
		let count+=1
		echo -e "\033[32m$supervisorFileName 已经存在\033[0m"
	fi
	
	# 安装meld3-1.0.2
	cd $installPath/$meldFileName/
	echo "123456"|sudo -S chown -R yuantiaotech:yuantiaotech $installPath/$meldFileName
	echo "123456"|sudo -S chmod -R 777 $installPath/$meldFileName
	echo "123456"|sudo -S python setup.py install
	if [ $? -eq 0 ]; then
		let count+=1
		echo -e "\033[32mmeld 安装完成\033[0m"
	else
		echo -e "\033[31mmeld 安装失败\033[0m"
	fi
	# 安装supervisor-3.3.1
	cd $installPath/$supervisorFileName/
	echo "123456"|sudo -S chown -R yuantiaotech:yuantiaotech $installPath/$supervisorFileName
	echo "123456"|sudo -S chmod -R 777 $installPath/$supervisorFileName
	echo "123456"|sudo -S python setup.py install
	if [ $? -eq 0 ]; then
		let count+=1
		echo -e "\033[32msupervisor 安装完成\033[0m"
	else
		echo -e "\033[31msupervisor 安装失败\033[0m"
	fi

	# 创建conf.d
	echo "123456"|sudo -S mkdir -p /etc/supervisor/conf.d
	
	# 初始化supervisord.conf
	echo "123456"|sudo -S su - root -c "echo_supervisord_conf > /etc/supervisor/supervisord.conf"
	echo "123456"|sudo -S sed -i '$d' /etc/supervisor/supervisord.conf
	echo "123456"|sudo -S sed -i '$d' /etc/supervisor/supervisord.conf
	echo "123456"|sudo -S sed -i '$a[include]' /etc/supervisor/supervisord.conf
	echo "123456"|sudo -S sed -i '$afiles = /etc/supervisor/conf.d/*.conf' /etc/supervisor/supervisord.conf

	# 拷贝启动脚本到/etc/init.d/
	echo "123456"|sudo -S cp $all_packages_path/supervisord /etc/init.d/
	# 检测java路径配置
	javaPath=$(echo "\"\$PATH:$JAVA_HOME/bin\"")
	echo "当前java路径：$javaPath"
	if cat /etc/init.d/supervisord | grep $javaPath >/dev/null
		then
		let count+=1
		echo -e "\033[32msupervisord 脚本JAVA路径配置正确\033[0m"
	else
		echo "123456"|sudo -S sed -i '/export PATH=/d'  /etc/init.d/supervisord
	    echo "123456"|sudo -S sed -i '3a export PATH='$(echo $javaPath)'' /etc/init.d/supervisord
	    if [ $? -eq 0 ]; then
			let count+=1
			echo -e "\033[32msupervisord 脚本JAVA路径配置成功\033[0m"
		else
			echo -e "\033[31msupervisord 脚本JAVA路径配置失败\033[0m"
		fi
	fi
	echo "123456"|sudo -S chmod 755 /etc/init.d/supervisord
	
	# 开机自启
	echo "123456"|sudo -S chkconfig --add supervisord
	echo "123456"|sudo -S chkconfig supervisord on

	if [ $? -eq 0 ]; then
		let count+=1
		echo -e "\033[32mSupervisor 开机自启配置成功\033[0m"
	else
		echo -e "\033[31mSupervisor 开机自启配置失败\033[0m"
	fi

	if [ "$count" == 6 ]; then
		echo -e "\033[32mSupervisor --------------------------- [安装成功]\033[0m"
		echo -e "\033[32m正在启动 Supervisor...\033[0m"
		sleep 2
		echo "123456"|sudo -S service supervisord start
	elif [ "$count" != 6 ]; then
		echo -e "\033[31mSupervisor --------------------------- [安装失败]\033[0m"
	fi
}

#==================================================================== MySQL安装、卸载选项 ====================================================================
MySQLInstallSelect(){
	echo -e "\033[32m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\033[0m"
	echo -e "\033[32m┠┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ MySQL ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┨\033[0m"
	echo -e "\033[32m┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫\033[0m"
	echo -e "\033[32m┃ [1]MySQL安装                  [2]MySQL卸载 ┃\033[0m"
	echo -e "\033[32m┃ [B]返回主菜单                 [Q]退出安装  ┃\033[0m"
	echo -e "\033[32m┃                                            ┃\033[0m"
	echo -e "\033[32m┃ *卸载操作请谨慎使用！做好数据备份！        ┃\033[0m"
	echo -e "\033[32m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\033[0m"

	read -p "请选择:" val
	case $val in
		1)	MySQLInstall
		;;
		2)	MySQLUninstallSelect
		;;
		B|b)  allInstallMenu
		;;
		Q|q)  exit 0
		;;
		*)  echo -e "\033[31m输入有误\033[0m"
			return
		;;
	esac
}

#==================================================================== MySQL卸载前确认 ====================================================================
MySQLUninstallSelect(){
	echo -e "\033[31m当前服务器IP地址:$IP_address请确认！\033[0m"
	read -p "注意！你正在删除MySQL，是否确定[Y/N]:" val
	case $val in
		Y|y)  MySQLUninstall
		;;
		N|n)  allInstallMenu
		;;
		*)	echo -e "\033[31m输入有误\033[0m"
			return
		;;
	esac
}

#==================================================================== MySQL卸载 ====================================================================
MySQLUninstall(){
	count=0
	oldMySQL=`rpm -qa | grep -i mysql`
	echo -e "\033[32m已安装列表:\033[0m"
	echo -e "\033[32m$oldMySQL\033[0m"
	sleep 2
	if [ ! -n "$oldMySQL" ]; then
		echo -e "\033[32m旧版本 MySQL 已经卸载\033[0m"
	else
		echo -e "\033[31m关闭MySQL...\033[0m"
		# 关闭MySQL
		MySQLStatus=`sudo service mysql status`
		status=`echo ${MySQLStatus%!*}`
		if [ "$status" == "SUCCESS" ]; then
			echo -e "\033[32mMySQL 正在关闭...请等待...\033[0m"
			echo "123456"|sudo -S su - root -c "service mysql stop"
		else
			echo -e "\033[32mMySQL 已经关闭\033[0m"
		fi
		# 卸载旧版本Mysql
		echo -e "\033[31m开始卸载旧版本...请稍等...\033[0m"
		sleep 1
		echo "123456"|sudo -S su - root -c "yum -y remove mysql-libs-5.1.73-7.el6.x86_64"
		echo "123456"|sudo -S su - root -c "yum -y remove MySQL-server-5.6.36-1.el6.x86_64"
		echo "123456"|sudo -S su - root -c "yum -y remove MySQL-client-5.6.36-1.el6.x86_64"
		echo "123456"|sudo -S su - root -c "yum -y remove MySQL-embedded-5.6.36-1.el6.x86_64"
		echo "123456"|sudo -S su - root -c "yum -y remove MySQL-shared-5.6.36-1.el6.x86_64"
		echo "123456"|sudo -S su - root -c "yum -y remove MySQL-test-5.6.36-1.el6.x86_64"
		echo "123456"|sudo -S su - root -c "yum -y remove MySQL-devel-5.6.36-1.el6.x86_64"
		echo "123456"|sudo -S su - root -c "yum -y remove MySQL-shared-compat-5.6.36-1.el6.x86_64"

		# 删除MySQL路径
		echo -e "\033[31m开始删除旧版本路径...请稍等...\033[0m"
		sleep 1
		echo "123456"|sudo -S rm -rf /var/lib/mysql
		echo "123456"|sudo -S rm -rf /usr/lib64/mysql
		echo "123456"|sudo -S rm -rf /usr/share/mysql
		echo "123456"|sudo -S rm -rf /etc/my.cnf

		if [ $? -eq 0 ]; then
			let count+=1
			echo -e "\033[32mMySQL --------------------------- [卸载成功]\033[0m"
		else
			echo -e "\033[31mMySQL --------------------------- [卸载失败]\033[0m"
			return
		fi
	fi
}

#==================================================================== MySQL安装 ====================================================================
MySQLInstall(){
	# 检查旧版本
	MySQLUninstallSelect
	# 计数
	count=0
	# 解压
	if [ ! -d $all_packages_path/MySQL-server-5.6.36-1.el6.x86_64.rpm ]; then
		if [ ! -f $all_packages_path/MySQL-5.6.36-1.el6.x86_64.rpm-bundle.tar ]; then
			echo -e "\033[31m错误：MySQL-5.6.36-1.el6.x86_64.rpm-bundle.tar压缩包不存在，先将压缩包拷贝至$all_packages_path路径下！\033[0m"
			return
		else
			tar xvf $all_packages_path/MySQL-5.6.36-1.el6.x86_64.rpm-bundle.tar -C $all_packages_path
			if [ $? -eq 0 ]; then
				let count+=1
				echo -e "\033[32mMySQL-5.6.36-1.el6.x86_64.rpm-bundle.tar 解压成功\033[0m"
			else
				echo -e "\033[31mMySQL-5.6.36-1.el6.x86_64.rpm-bundle.tar 解压失败\033[0m"
				return
			fi
			sleep 2
		fi
	else
		echo -e "\033[32mMySQL-5.6.36-1.el6.x86_64.rpm-bundle.tar 已经解压\033[0m"
	fi
	echo -e "\033[32m开始安装 MySQL\033[0m"
	sleep 1
	echo "123456"|sudo -S rpm -ivh --nodeps --force $all_packages_path/MySQL-client-5.6.36-1.el6.x86_64.rpm
	echo "123456"|sudo -S rpm -ivh --nodeps --force $all_packages_path/MySQL-devel-5.6.36-1.el6.x86_64.rpm
	echo "123456"|sudo -S rpm -ivh --nodeps --force $all_packages_path/MySQL-embedded-5.6.36-1.el6.x86_64.rpm
	echo "123456"|sudo -S rpm -ivh --nodeps --force $all_packages_path/MySQL-server-5.6.36-1.el6.x86_64.rpm
	echo "123456"|sudo -S rpm -ivh --nodeps --force $all_packages_path/MySQL-shared-5.6.36-1.el6.x86_64.rpm
	echo "123456"|sudo -S rpm -ivh --nodeps --force $all_packages_path/MySQL-shared-compat-5.6.36-1.el6.x86_64.rpm
	echo "123456"|sudo -S rpm -ivh --nodeps --force $all_packages_path/MySQL-test-5.6.36-1.el6.x86_64.rpm
	if [ $? -eq 0 ]; then
		let count+=1
		echo -e "\033[32mMySQL 压缩包安装完成\033[0m"
	else
		echo -e "\033[31mMySQL 压缩包安装失败\033[0m"
		return
	fi

	# 设置开机自启
	echo "123456"|sudo -S chkconfig mysql on
	# 配置my.cnf文件
	if [ ! -f /etc/my.cnf ]; then
		echo "123456"|sudo -S su - root -c "echo "[mysqld]" >> /etc/my.cnf"
		echo "123456"|sudo -S sed -i '$adatadir=/var/lib/mysql' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$asocket=/var/lib/mysql/mysql.sock' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$auser=mysql' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$aport=3306' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$alower_case_table_names=1' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$acharacter-set-server=utf8' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$asymbolic-links=0' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$askip-name-resolve' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$anet_write_timeout=600' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$await_timeout=31536000' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$ainteractive_timeout=31536000' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$acollation-server=utf8_general_ci' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$askip-external-locking' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$akey_buffer=512M' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$amax_allowed_packet=16M' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$athread_stack=192K' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$athread_cache_size=8' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$aread_rnd_buffer_size=2560M' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$asort_buffer_size=2560M' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$ajoin_buffer_size=2560M' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$ainnodb_buffer_pool_size=6G' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$aread_buffer_size=2560M' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$amyisam-recover=BACKUP' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$atmp_table_size=512M' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$amax_connections=1500' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$aquery_cache_limit=256M' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$aquery_cache_size=1024M' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$aexpire_logs_days=10' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$amax_binlog_size=100M' /etc/my.cnf
		
		echo "123456"|sudo -S sed -i '$a[client]' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$aport=3306' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$adefault-character-set=utf8' /etc/my.cnf

		echo "123456"|sudo -S sed -i '$a[mysqld_safe]' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$alog-error=/var/log/mysqld.log' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$asocket=/var/lib/mysql/mysql.sock' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$apid-file=/var/lib/mysql/mysql.pid' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$anice=0' /etc/my.cnf

		echo "123456"|sudo -S sed -i '$a[mysqldump]' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$aquick' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$aquote-names' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$amax_allowed_packet=1024M' /etc/my.cnf

		echo "123456"|sudo -S sed -i '$a[mysql]' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$a[isamchk]' /etc/my.cnf
		echo "123456"|sudo -S sed -i '$akey_buffer=16M' /etc/my.cnf
		echo "123456"|sudo -S chmod 644 /etc/my.cnf

		if [ $? -eq 0 ]; then
			let count+=1
			echo -e "\033[32m/etc/my.cnf 创建成功\033[0m"
		else
			echo -e "\033[31m/etc/my.cnf 创建失败\033[0m"
		fi
	else
		let count+=1
		echo -e "\033[32m/etc/my.cnf 文件已经存在\033[0m"
	fi

	if [ "$count" == 3 ]; then
		echo -e "\033[32mMySQL --------------------------- [安装成功]\033[0m"
		# 启动Mysql
		echo -e "\033[32m正在启动 MySQL...\033[0m"
		sleep 2
		echo "123456"|sudo -S service mysql start
	elif [ "$count" != 3 ]; then
		echo -e "\033[31mMySQL --------------------------- [安装失败]\033[0m"
		return
	fi
	
	# 修改/etc/hosts
	addHostName

	# 显示初始密码
	pwdFile=`sudo cat /root/.mysql_secret`
	initPwd=${pwdFile##*: }
	echo -e "\033[32mMySQL 初始密码:${initPwd}\033[0m"

	# 修改初始密码
	mysqladmin -uroot -p${initPwd} password 123456
	if [ $? -eq 0 ]; then
		echo -e "\033[32mMySQL 初始密码修改成功\033[0m"
	else
		echo -e "\033[31mMySQL 初始密码修改失败\033[0m"
	fi

	# 开启远程访问权限
	mysql -uroot -p123456 <<EOF
	grant all privileges on *.* to 'root'@'%' identified by '123456' with grant option;
	grant all privileges on *.* to 'scm'@'%' identified by 'scm' with grant option;
	USE mysql;
	UPDATE user SET Password=PASSWORD('123456') WHERE user='root';
	UPDATE user SET password_expired='N';
	FLUSH PRIVILEGES;
EOF
	if [ $? -eq 0 ]; then
		echo -e "\033[32mMySQL 远程访问开启成功\033[0m"
	else
		echo -e "\033[31mMySQL 远程访问开启失败\033[0m"
	fi
}

#==================================================================== Oracle安装、配置、卸载选项 ====================================================================
OracleInstallSelect(){
	echo -e "\033[32m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\033[0m"
	echo -e "\033[32m┠┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Oracle ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┨\033[0m"
	echo -e "\033[32m┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫\033[0m"
	echo -e "\033[32m┃ [1]Oracle安装                [2]Oracle配置 ┃\033[0m"
	echo -e "\033[32m┃ [3]Oracle卸载                              ┃\033[0m"
	echo -e "\033[32m┃ [B]返回主菜单                [Q]退出安装   ┃\033[0m"
	echo -e "\033[32m┃                                            ┃\033[0m"
	echo -e "\033[32m┃ *完整安装Oracle需包含[1][2]两步            ┃\033[0m"
	echo -e "\033[32m┃ *卸载操作请谨慎使用！做好数据备份！        ┃\033[0m"
	echo -e "\033[32m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\033[0m"

	read -p "请选择:" val
	case $val in
		1)	OracleInstall
		;;
		2)	OracleConfigure
		;;
		3)	OracleUninstall
		;;
		B|b)  allInstallMenu
		;;
		Q|q)  exit 0
		;;
		*)  echo -e "\033[31m输入有误\033[0m"
			return
		;;
	esac
}

#==================================================================== Oracle安装 ====================================================================
OracleInstall(){
	# 卸载Oracle
	if [ "$ORACLE_HOME" != "" ]; then
		OracleUninstallSelect
	fi
	
	# 解压依赖包
	if [ ! -d $all_packages_path/centos6.8_oracle11gPackages ]; then
		if [ ! -f $all_packages_path/centos6.8_oracle11gPackages.tar.gz ]; then
			echo -e "\033[31m错误：centos6.8_oracle11gPackages.tar压缩包不存在，先将压缩包拷贝至$all_packages_path路径下！\033[0m"
			return
		else
			tar zxvf $all_packages_path/centos6.8_oracle11gPackages.tar.gz -C $all_packages_path
			if [ $? -eq 0 ]; then
				echo -e "\033[32mcentos6.8_oracle11gPackages.tar 解压成功\033[0m"
			else
				echo -e "\033[31mcentos6.8_oracle11gPackages.tar 解压失败\033[0m"
				return
			fi
			sleep 3
		fi
	else
		echo -e "\033[32mmcentos6.8_oracle11gPackages 已经存在\033[0m"
		echo "123456"|sudo -S rpm -ivh --force --nodeps $all_packages_path/centos6.8_oracle11gPackages/part1/*.rpm 
		echo "123456"|sudo -S rpm -ivh --force --nodeps $all_packages_path/centos6.8_oracle11gPackages/part2_xhost/*.rpm 
	fi
	
	# 修改/etc/hosts
	addHostName
	
	# 配置内核参数及用户限制 /etc/sysctl.conf
	if cat /etc/sysctl.conf | grep Oracle11gR2 >/dev/null
		then
		echo -e "\033[32m/etc/sysctl.conf 环境变量已经存在\033[0m"
	else
		echo "123456"|sudo -S sed -i '$a# Oracle11gR2 kernel parameters' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '$afs.aio-max-nr=1048576' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '$afs.file-max=6815744' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '$akernel.shmall = 2097152' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '$akernel.shmmni = 4096' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '$akernel.sem=250	32000	100	128' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '$akernel.shmmax=2147483648' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '$anet.ipv4.ip_local_port_range=9000 65500' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '$anet.core.rmem_default=262144' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '$anet.core.rmem_max=4194304' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '$anet.core.wmem_default=262144' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '$anet.core.wmem_max=1048586' /etc/sysctl.conf
		# 生效配置
		echo "123456"|sudo -S su - root -c "sysctl -p"
	fi
	
	# 配置用户资源限制文件 /etc/security/limits.conf
	if cat /etc/security/limits.conf | grep Oracle11gR2 >/dev/null
		then
		echo -e "\033[32m/etc/security/limits.conf 环境变量已经存在\033[0m"
	else
		echo "123456"|sudo -S sed -i '$a# Oracle11gR2 shell limits' /etc/security/limits.conf
		echo "123456"|sudo -S sed -i '$ayuantiaotech soft nproc 2048' /etc/security/limits.conf
		echo "123456"|sudo -S sed -i '$ayuantiaotechhard nproc 16384' /etc/security/limits.conf
		echo "123456"|sudo -S sed -i '$ayuantiaotechsoft nofile 1024' /etc/security/limits.conf
		echo "123456"|sudo -S sed -i '$ayuantiaotechhard nofile 65536' /etc/security/limits.conf
		echo "123456"|sudo -S sed -i '$ayuantiaotechsoft stack 10240' /etc/security/limits.conf
	fi
	

	# 配置登录限制 /etc/pam.d/login及/etc/pam.d/su
	if cat /etc/pam.d/login | grep Oracle11gR2 >/dev/null
		then
		echo -e "\033[32m/etc/sysctl.conf 环境变量已经存在\033[0m"
	else
		echo "123456"|sudo -S sed -i '$a# Oracle11gR2 shell limits' /etc/pam.d/login
		echo "123456"|sudo -S sed -i '$asession required pam_limits.so' /etc/pam.d/login
	fi
	if cat /etc/pam.d/su | grep Oracle11gR2 >/dev/null
		then
		echo -e "\033[32m/etc/sysctl.conf 环境变量已经存在\033[0m"
	else
		echo "123456"|sudo -S sed -i '$a# Oracle11gR2 shell limits' /etc/pam.d/su
		echo "123456"|sudo -S sed -i '$asession required pam_limits.so' /etc/pam.d/su
	fi

	# 创建/opt
	if [ ! -d /opt/ ]; then
	    echo "123456"|sudo -S su - root -c "mkdir /opt/"
	else
	    echo -e "\033[32m/opt/ 路径已经存在\033[0m"
	fi
	echo "123456"|sudo -S chown -R yuantiaotech /opt/
	echo "123456"|sudo -S chmod -R 775 /opt/

	# 配置/etc/profile环境变量
	if cat /etc/profile | grep ORACLE_HOME >/dev/null
		then
		echo -e "\033[32m/etc/profile 环境变量已经存在\033[0m"
	else
		echo "123456"|sudo -S sed -i '$a# Oracle11gR2 shell limits' /etc/profile
		echo "123456"|sudo -S sed -i '$aexport ORACLE_BASE=/opt/app/oracle' /etc/profile
		echo "123456"|sudo -S sed -i '$aexport ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1' /etc/profile
		echo "123456"|sudo -S sed -i '$aexport ORACLE_OWNER=yuantiaotech' /etc/profile
		echo "123456"|sudo -S sed -i '$aexport ORACLE_SID=orcl' /etc/profile
		echo "123456"|sudo -S sed -i '$aexport NLS_LANG=.AL32UTF8' /etc/profile
		echo "123456"|sudo -S sed -i '$aexport PATH=$PATH:$ORACLE_HOME/bin' /etc/profile
		# 生效配置
		source /etc/profile
	fi
	
	# 建立库链接
	if [ ! -d /usr/lib64 ]; then
	    echo "123456"|sudo -S su - root -c "mkdir /usr/lib64"
	else
	    echo -e "\033[32m/usr/lib64 路径已经存在\033[0m"
	fi
	echo "123456"|sudo -S ln -s /etc /etc/rc.d
	echo "123456"|sudo -S ln -s /usr/bin/awk /bin/awk
	echo "123456"|sudo -S ln -s /usr/bin/basename /bin/basename
	echo "123456"|sudo -S ln -s /usr/bin/rpm /bin/rpm
	echo "123456"|sudo -S ln -s /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib64/
	echo "123456"|sudo -S ln -s /usr/lib/x86_64-linux-gnu/libc_nonshared.a /usr/lib64/
	echo "123456"|sudo -S ln -s /usr/lib/x86_64-linux-gnu/libpthread_nonshared.a /usr/lib64/
	echo "123456"|sudo -S ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib64/

	# 设置Linux版本
	echo "123456"|sudo -S su - root -c "echo 'Red Hat Linux release 5' > /etc/redhat-release"

	echo "123456"|sudo -S export LANG=en_US

	# 创建并且配置/etc/init.d/oracle 开机启动脚本
	if [ ! -f /etc/init.d/oracle ]; then
		echo "123456"|sudo -S su - root -c "echo '#! /bin/sh' >> /etc/init.d/oracle"
		echo "123456"|sudo -S sed -i '$aexport ORACLE_BASE=/opt/app/oracle' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aexport ORACLE_HOME=/opt/app/oracle/product/11.2.0/dbhome_1' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aexport ORACLE_OWNER=yuantiaotech' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aexport ORACLE_SID=orcl' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aexport PATH=$PATH:$ORACLE_HOME/bin' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aif [ ! -f $ORACLE_HOME/bin/dbstart -o ! -d $ORACLE_HOME ]' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$athen' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aecho "Oracle startup: cannot start"' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aexit 1' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$afi' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$acase "$1" in' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$astart)' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$a# Oracle listener and instance startup' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aecho -n "Starting Oracle: "' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$asu - $ORACLE_OWNER -c "$ORACLE_HOME/bin/dbstart $ORACLE_HOME"' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aecho "OK"' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$a;;' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$astop)' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$a# Oracle listener and instance shutdown' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aecho -n "Shutdown Oracle: "' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$asu - $ORACLE_OWNER -c "$ORACLE_HOME/bin/dbshut $ORACLE_HOME"' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aecho "OK"' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$a;; ' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$areload|restart)' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$a$0 stop' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$a$0 start' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$a;;' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$a*)' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aecho "Usage: `basename $0` start|stop|restart|reload"' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aexit 1' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aesac' /etc/init.d/oracle
		echo "123456"|sudo -S sed -i '$aexit 0' /etc/init.d/oracle
		echo "123456"|sudo -S chmod 755 /etc/init.d/oracle

		#设置文件软链接
		echo "123456"|sudo -S ln -s /etc/init.d/oracle /etc/rc.d/rc2.d/S99oracle
		echo "123456"|sudo -S ln -s /etc/init.d/oracle /etc/rc.d/rc3.d/S99oracle
		echo "123456"|sudo -S ln -s /etc/init.d/oracle /etc/rc.d/rc4.d/S99oracle
		echo "123456"|sudo -S ln -s /etc/init.d/oracle /etc/rc.d/rc5.d/S99oracle
		echo "123456"|sudo -S ln -s /etc/init.d/oracle /etc/rc.d/rc0.d/K01oracle
		echo "123456"|sudo -S ln -s /etc/init.d/oracle /etc/rc.d/rc1.d/K01oracle
		echo "123456"|sudo -S ln -s /etc/init.d/oracle /etc/rc.d/rc6.d/K01oracle
		if [ $? -eq 0 ]; then
			echo -e "\033[32m/etc/init.d/oracle 开机启动脚本创建成功\033[0m"
		else
			echo -e "\033[31m/etc/init.d/oracle 开机启动脚本创建失败\033[0m"
		fi
	else
		echo -e "\033[32m/etc/init.d/oracle 开机启动脚本已经存在\033[0m"
	fi
	
	# 解压安装包
	if [ ! -d $all_packages_path/database ]; then
		if [ ! -f $all_packages_path/centos6.8_oracle11gPackages.tar.gz ]; then
			echo -e "\033[31m错误：centos6.8_oracle11gPackages.tar压缩包不存在，先将压缩包拷贝至$all_packages_path路径下！\033[0m"
			return
		else
			unzip $all_packages_path/linux.x64_11gR2_database_1of2.zip -d $all_packages_path
			unzip $all_packages_path/linux.x64_11gR2_database_2of2.zip -d $all_packages_path
			if [ $? -eq 0 ]; then
				echo -e "\033[32mOracle 安装包解压成功\033[0m"
			else
				echo -e "\033[31mOracle 安装包解压失败\033[0m"
				return
			fi
			sleep 3
		fi
	else
		echo -e "\033[32mOracle 安装包已经解压\033[0m"
	fi
	# 图形程序显示到桌面上DISPLAY设置
	IP_xhost=0
	stty erase ^H
	read -p "输入笔记本IP地址(例如192.168.0.111):" val
	case $val in
		*)	IP_xhost=$val
			export DISPLAY=$IP_xhost:0.0
			xhost +
		;;
	esac

	# 安装
	check_user=`whoami`  
    if [ "$check_user" != "root" ]  
    then
		cd $all_packages_path/database
		./runInstaller
		# Oracle静默安装
		#./runInstaller -silent -force -ignorePrereq -ignoreSysPrereqs -responseFile /tmp/db_install.rsp
	else
		echo -e "\033[31m当前为root用户，用非root用户重新执行脚本。\033[0m"
		return
    fi
}

#==================================================================== Oracle配置 ====================================================================
OracleConfigure(){
	if cat /etc/oratab | grep dbhome_1:Y >/dev/null
		then
		echo -e "\033[32m/etc/oratab 已经配置\033[0m"
	else
		echo "123456"|sudo -S sed -i "s/dbhome_1:N/dbhome_1:Y/g" /etc/oratab
		if [ $? -eq 0 ]; then
			echo -e "\033[32m/etc/oratab 配置成功\033[0m"
			# 启动Oracle
			dbstart $ORACLE_HOME
		else
			echo -e "\033[31m/etc/oratab 配置失败\033[0m"
			return
		fi
	fi

	echo -e "\033[32m正在检查配置...请等待...\033[0m"
	sleep 1
	myHostName=`hostname`
	if cat $ORACLE_HOME/network/admin/listener.ora | grep $myHostName >/dev/null
		then
		echo -e "\033[32mlistener.ora 主机名配置正确\033[0m"
	else
		echo -e "\033[31mlistener.ora 主机名配置错误\033[0m"
	fi

	if cat $ORACLE_HOME/network/admin/tnsnames.ora | grep $myHostName >/dev/null
		then
		echo -e "\033[32mtnsnames.ora 主机名配置正确\033[0m"
	else
		echo -e "\033[31mtnsnames.ora 主机名配置错误\033[0m"
	fi

	echo -e "\033[32m开始创建amoy用户及配置内存等...请等待...\033[0m"
	# 创建amoy用户及配置
	sqlplus /nolog <<EOF
	connect / as sysdba;
	create user amoy identified by 123456;
	connect system as sysdba;
	grant dba to amoy;
	connect amoy/123456;
	alter database add supplemental log data (all) columns;
	connect / as sysdba;
	alter system set sga_max_size=384m scope=spfile;
	alter system set sga_target=384m scope=spfile;
	alter system set pga_aggregate_target=96m;
	alter system set PROCESSES=300 scope=spfile;
	alter profile default limit password_life_time unlimited;
	shutdown immediate;
	startup;
	exit
EOF

	# 还原系统版本信息
	echo "123456"|sudo -S su - root -c "echo 'CentOS release 6.8 (Final)' > /etc/redhat-release"

	if [ $? -eq 0 ]; then
		echo -e "\033[32mOracle 配置成功\033[0m"
	else
		echo -e "\033[31mOracle 配置失败\033[0m"
		return
	fi
}

#==================================================================== Oracle卸载前确认 ====================================================================
OracleUninstallSelect(){
	echo -e "\033[31m当前服务器IP地址:$IP_address请确认！\033[0m"
	read -p "注意！你正在删除Oracle，是否确定[Y/N]:" val
	case $val in
		Y|y)  OracleUninstall
		;;
		N|n)  allInstallMenu
		;;
		*)	echo -e "\033[31m输入有误\033[0m"
			return
		;;
	esac
}

#==================================================================== Oracle卸载 ====================================================================
OracleUninstall(){
	# 关闭Oracle
	if [ -f /opt/app/oracle/product/11.2.0/dbhome_1/bin/sqlplus ]; then
		echo -e "\033[32m关闭Oracle...\033[0m"
		sqlplus /nolog <<EOF
		connect / as sysdba;
		shutdown immediate;
		exit
EOF
	fi

	# 关闭Oralce监听
	if [ -f /opt/app/oracle/product/11.2.0/dbhome_1/bin/lsnrctl ]; then	
		echo "123456"|sudo -S su - root -c "lsnrctl stop"
	fi
	echo -e "\033[32m开始卸载Oracle\033[0m"
	count=0
	# 删除安装路径
	echo "123456"|sudo -S su - root -c "rm -rf /opt/app"
	echo "123456"|sudo -S su - root -c "rm -rf /opt/ORCLfmap"
	if [ $? -eq 0 ]; then
		let count+=1
		echo -e "\033[32mOracle 安装路径删除成功\033[0m"
	else
		echo -e "\033[31mOracle 安装路径删除失败\033[0m"
	fi

	# 删除/usr/local/bin下三个文件夹
	echo "123456"|sudo -S su - root -c "rm -rf /usr/local/bin/dbhome"
	echo "123456"|sudo -S su - root -c "rm -rf /usr/local/bin/oraenv"
	echo "123456"|sudo -S su - root -c "rm -rf /usr/local/bin/coraenv"
	if [ $? -eq 0 ]; then
		echo -e "\033[32m/usr/local/bin 下配置文件夹删除成功\033[0m"
		let count+=1
	else
		echo -e "\033[31m/usr/local/bin 下配置文件夹删除失败\033[0m"
	fi

	# 删除/etc下文件
	echo "123456"|sudo -S su - root -c "rm -f /etc/oratab"
	echo "123456"|sudo -S su - root -c "rm -f /etc/oraInst.loc"
	if [ $? -eq 0 ]; then
		echo -e "\033[32m/etc/ 下配置文件夹删除成功\033[0m"
		let count+=1
	else
		echo -e "\033[31m/etc/ 下配置文件夹删除失败\033[0m"
	fi

	# 删除配置
	if cat /etc/sysctl.conf | grep Oracle11gR2 >/dev/null
		then
		echo "123456"|sudo -S sed -i '/Oracle11gR2/d' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '/fs.aio-max-nr/d' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '/fs.file-max/d' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '/kernel.shmall/d' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '/kernel.shmmni/d' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '/kernel.sem/d' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '/kernel.shmmax/d' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '/net.core.rmem_default/d' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '/net.core.wmem_default/d' /etc/sysctl.conf
		echo "123456"|sudo -S sed -i '/net.core.wmem_max/d' /etc/sysctl.conf
		echo -e "\033[32m/etc/sysctl.conf 中Oracle配置删除成功\033[0m"
	else
		echo -e "\033[32m/etc/sysctl.conf 中Oracle配置不存在\033[0m"
	fi

	if cat /etc/security/limits.conf | grep Oracle11gR2 >/dev/null
		then
		echo "123456"|sudo -S sed -i '/Oracle11gR2/d' /etc/security/limits.conf
		echo "123456"|sudo -S sed -i '/yuantiaotech soft nproc 2048/d' /etc/security/limits.conf
		echo "123456"|sudo -S sed -i '/yuantiaotechhard nproc 16384/d' /etc/security/limits.conf
		echo "123456"|sudo -S sed -i '/yuantiaotechsoft nofile 1024/d' /etc/security/limits.conf
		echo "123456"|sudo -S sed -i '/yuantiaotechhard nofile 65536/d' /etc/security/limits.conf
		echo "123456"|sudo -S sed -i '/yuantiaotechsoft stack 10240/d' /etc/security/limits.conf
		echo -e "\033[32m/etc/security/limits.conf 中Oracle配置删除成功\033[0m"
	else
		echo -e "\033[32m/etc/security/limits.conf 中Oracle配置不存在\033[0m"
	fi

	if cat /etc/pam.d/su | grep Oracle11gR2 >/dev/null
		then
		echo "123456"|sudo -S sed -i '/Oracle11gR2/d' /etc/pam.d/su
		echo "123456"|sudo -S sed -i '/session required pam_limits.so/d' /etc/pam.d/su
		echo -e "\033[32m/etc/pam.d/su 中Oracle配置删除成功\033[0m"
	else
		echo -e "\033[32m/etc/pam.d/su 中Oracle配置不存在\033[0m"
	fi

	if cat /etc/pam.d/login | grep Oracle11gR2 >/dev/null
		then
		echo "123456"|sudo -S sed -i '/Oracle11gR2/d' /etc/pam.d/login
		echo "123456"|sudo -S sed -i '/session required pam_limits.so/d' /etc/pam.d/login
		echo -e "\033[32m/etc/pam.d/login 中Oracle配置删除成功\033[0m"
	else
		echo -e "\033[32m/etc/pam.d/login 中Oracle配置不存在\033[0m"
	fi

	if cat /etc/profile | grep Oracle11gR2 >/dev/null
		then
		echo "123456"|sudo -S sed -i '/Oracle11gR2/d' /etc/profile
		echo "123456"|sudo -S sed -i '/export ORACLE_BASE/d' /etc/profile
		echo "123456"|sudo -S sed -i '/export ORACLE_HOME/d' /etc/profile
		echo "123456"|sudo -S sed -i '/export ORACLE_OWNER/d' /etc/profile
		echo "123456"|sudo -S sed -i '/export ORACLE_SID/d' /etc/profile
		echo "123456"|sudo -S sed -i '/export NLS_LANG=.AL32UTF8/d' /etc/profile
		echo "123456"|sudo -S sed -i '/export PATH=\$PATH:\$ORACLE_HOME\/bin/d' /etc/profile
		echo -e "\033[32m/etc/profile 中Oracle配置删除成功\033[0m"
	else
		echo -e "\033[32m/etc/profile 中Oracle配置不存在\033[0m"
	fi

	if [ "$count" == 3 ]; then
		echo -e "\033[32mOracle --------------------------- [卸载成功]\033[0m"
	elif [ "$count" != 3 ]; then
		echo -e "\033[31mOracle --------------------------- [卸载失败]\033[0m"
	fi
}

#==================================================================== 关闭防火墙 ====================================================================
closeFirewall(){
	# 关闭防火墙
	echo "123456"|sudo -S service iptables status
	if [ $? -eq 0 ]; then
		echo -e "\033[32m正在关闭防火墙...\033[0m"
		sleep 1
		echo "123456"|sudo -S service iptables stop
		if [ $? -eq 0 ]; then
			echo -e "\033[32m临时关闭防火墙成功\033[0m"
		else
			echo -e "\033[31m临时关闭防火墙失败\033[0m"
		fi

		echo "123456"|sudo -S chkconfig iptables off
		if [ $? -eq 0 ]; then
			echo -e "\033[32m永久关闭防火墙成功，重启后生效\033[0m"
		else
			echo -e "\033[31m永久关闭防火墙失败\033[0m"
		fi
    else 
    	echo -e "\033[32m防火墙已经关闭\033[0m"
    fi

	# 关闭SELINUX
	sleep 1
	if cat /etc/selinux/config | grep SELINUX=disabled >/dev/null
		then
		echo -e "\033[32mSELINUX 已经关闭\033[0m"
	else
		echo -e "\033[32m正在关闭SELINUX...\033[0m"
		echo "123456"|sudo -S sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
		if [ $? -eq 0 ]; then
			echo -e "\033[32mSELINUX 关闭成功，重启服务器后生效\033[0m"
		else
			echo -e "\033[31mSELINUX 关闭失败\033[0m"
		fi
	fi
}

#==================================================================== ActiveMQ 安装 ====================================================================
ActiveMQInstall(){
	# ActiveMQ 安装路径
	ActiveMQinstallPath=/home/yuantiaotech
	# ActiveMQ 压缩包名
	ActiveMQPackageName=apache-activemq-5.14.2-bin.tar.gz
	# ActiveMQ 文件夹名
	ActiveMQFileName=apache-activemq-5.14.2

	# 检查安装路径
	checkInstallPath $ActiveMQinstallPath
	# 解压依赖包
	if [ ! -d $all_packages_path/$ActiveMQFileName ]; then
		if [ ! -f $all_packages_path/$ActiveMQPackageName ]; then
			echo -e "\033[31m错误：$ActiveMQPackageName压缩包不存在，先将压缩包拷贝至$all_packages_path路径下！\033[0m"
			return
		else
			tar zxvf $all_packages_path/$ActiveMQPackageName -C $ActiveMQinstallPath
			if [ $? -eq 0 ]; then
				echo -e "\033[32m$ActiveMQPackageName 解压成功\033[0m"
				let count+=1
			else
				echo -e "\033[31m$ActiveMQPackageName 解压失败\033[0m"
				return
			fi
			sleep 3
		fi
	else
		echo -e "\033[32mm$ActiveMQFileName 已经存在\033[0m"
		let count+=1
	fi

	# ActiveMQ内存限制
	echo "123456"|sudo -S sed -i '2a ACTIVEMQ_OPTS_MEMORY=\"-Xms512m -Xmx1024m\"' $ActiveMQinstallPath/$ActiveMQFileName/bin/activemq
	
	# 配置脚本JAVA_HOME路径
	echo "123456"|sudo -S ln -s $ActiveMQinstallPath/$ActiveMQFileName/bin/activemq /etc/init.d/
	echo "123456"|sudo -S sed -i '2a export JAVA_HOME='$(echo $JAVA_HOME)'' /etc/init.d/activemq
	echo "123456"|sudo -S sed -i '2a ACTIVEMQ_HOME='$(echo $ActiveMQinstallPath)'/'$(echo $ActiveMQFileName)'' /etc/init.d/activemq

	if [ $? -eq 0 ]; then
		echo -e "\033[32mactivemq 脚本配置成功\033[0m"
		let count+=1
	else
		echo -e "\033[31mactivemq 脚本配置失败\033[0m"
		return
	fi
	echo "123456"|sudo -S chmod 777 /etc/init.d/activemq

	# 开机自启
	echo "123456"|sudo -S chkconfig activemq on

	if [ "$count" == 2 ]; then
		echo -e "\033[32mActiveMQ --------------------------- [安装成功]\033[0m"
		service activemq start
	elif [ "$count" != 2 ]; then
		echo -e "\033[31mActiveMQ --------------------------- [安装失败]\033[0m"
	fi
}

#==================================================================== 检查安装路径是否存在 ====================================================================
checkInstallPath(){
	# 检查路径
	if [ ! -d $1 ]; then
	    mkdir -p $1
	    if [ $? -eq 0 ]; then
			echo -e "\033[32m$1 路径创建成功\033[0m"
		else
			echo -e "\033[31m$1 路径创建失败\033[0m"
			exit 0
		fi
	else
	    echo -e "\033[32m$1 路径已经存在\033[0m"
	fi
}

#==================================================================== 添加主机名 ====================================================================
addHostName(){
	# 获取本机IP
	myIP=`ifconfig | grep "inet addr:"|head -n 1 | awk '{print $2}' | sed 's/addr://g'`
	# 获取本机主机名
	myHostName=`hostname`
	# 检查并添加到/etc/hosts
	if cat /etc/hosts | grep $myHostName >/dev/null
	then
		echo -e "\033[32m/etc/hosts 已经添加主机名：$myHostName\033[0m"
	else
		echo "123456"|sudo -S sed -i '$a'$(echo $myIP)'    '$(echo $myHostName)'' /etc/hosts
	fi
}

#==================================================================== 主菜单 ====================================================================
allInstallMenu(){
	echo -e "\033[32m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\033[0m"
	echo -e "\033[32m┣━━━━━━━━━━━━━━━━━━ 主菜单 ━━━━━━━━━━━━━━━━━━┫\033[0m"
	echo -e "\033[32m┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫\033[0m"
	echo -e "\033[32m┃ [1]关闭防火墙             [2]创建/删除用户 ┃\033[0m"
	echo -e "\033[32m┃ [3]JDK                    [4]Supervisor    ┃\033[0m"
	echo -e "\033[32m┃ [5]MySQL                  [6]Oracle        ┃\033[0m"
	echo -e "\033[32m┃ [7]ActiveMQ               [8]Tomcat        ┃\033[0m"
	echo -e "\033[32m┃ [Q]退出安装                                ┃\033[0m"	
	echo -e "\033[32m┃                                            ┃\033[0m"	
	echo -e "\033[32m┃ *请根据菜单提示选择相应编号                ┃\033[0m"
	echo -e "\033[32m┃ *确保安装包已经放置在/tmp路径下            ┃\033[0m"
	echo -e "\033[32m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\033[0m"
	#stty erase ^H
	read -p "选择需要安装的软件编号:" val
	case $val in
		1)	closeFirewall
		;;
		2)	UserSelect
		;;
		3)  JDKInstall
		;;
		4)	SupervisorInstall
		;;
		5)	MySQLInstallSelect
		;;
		6)	OracleInstallSelect
		;;
		7)	ActiveMQInstall
 		;;
		8)	tomcatInstallSelect
 		;;
		Q|q)  exit 0
		;;
		*)  echo -e "\033[31m输入有误\033[0m"
			return
		;;
	esac
}
allInstallMenu