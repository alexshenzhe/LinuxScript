#!/bin/bash

# 文 件 名 : configFile_2.0.sh
# 作    者 : 沈喆
# 创建时间 : 2018/01/31
# 版    本 : 2.1.1
# 更新时间 : 2018/02/25
# 描    述 : 本脚本用于在态势2.0部署过程中对两个tomcat进行相应的配置。
# 			 一般将tomcat都部署在/home/yuantiaotech/project/aaron目录下，
#			 部署之前我们需要手动将tomcat的名称分别命名成tomcat_aaron以及tomcat_geoLayer，
#			 然后将tomcat放置在/tmp路径下，随后修改完毕脚本【手动修改】内容以后执行脚本即可，脚本会自行将tomcat需要修改IP及数据库名的内容以及端口自动完成修改，
#			 脚本支持自动生成supervisor下的conf文件。
#			 建议在yuantiaotech用户下运行脚本。

# -------------------------------------------------------------- 手动修改 --------------------------------------------------------------
camo_IP_database=192.168.0.112			# 大数据camo数据库服务器IP
aaron_IP_database=$camo_IP_database		# 应用aaron数据库服务器IP，一般情况下与大数据camo数据库服务器IP相同
camo_db_name=camo1.1.1.2				# 大数据camo数据库名称
aaron_db_name=aaron1.1.1.2				# 应用aaron数据库名称

# -------------------------------------------------------------- 脚本环境变量 --------------------------------------------------------------
all_packages_path=/tmp					# 安装包默认放置路径，所有安装包都会到这个路径下去读取
aaron_name=tomcat_aaron         		# tomcat文件夹名称
geoLayer_name=tomcat_geoLayer			# geoserver文件夹名称
insatll_path=/home/yuantiaotech/aaron	# 安装路径
# tomcat 配置文件路径
filePath_tomcat=$insatll_path/$aaron_name/webapps/pf.web.runtime/configuration/datasource.xml
# geoserver 配置文件路径
filePath_geoCamo=$insatll_path/$geoLayer_name/webapps/geoserver/data/workspaces/cite/qj/datastore.xml
filePath_geoAaron=$insatll_path/$geoLayer_name/webapps/geoserver/data/workspaces/cite/wx/datastore.xml
# tomcat 端口配置路径
filePath_tomcatPort=$insatll_path/$aaron_name/conf/server.xml
# geoLayer 端口配置路径
filePath_geoPort=$insatll_path/$geoLayer_name/conf/server.xml
# tomcat_aaron及tomcat_geoLayer 端口，默认将系统端口修改成如下端口
aaron_shutdownPort=8021
aaron_httpPort=8388
aaron_ajpPort=8033
geo_shutdownPort=8227
geo_httpPort=8385
geo_ajpPort=9395
# -------------------------------------------------------------- 临时环境变量 --------------------------------------------------------------
configPort_filePath=0		# tomcat的server.xml路径
file_DbName=0				# 文件中数据库名称
cat_port=0					# 截取端口的内容
port_name=0					# 端口名称
port_no=0					# 端口号
search_keyword=0			# 搜索关键字
db_or_ip=0					# 数据库或者IP名称
filePath_geoLayer=0			# geoLayer配置路径
tomcat_name=0				# tomcat名称
# ================================================================ tomcat_aaron配置 ================================================================
configTomcatAaron(){
	tomcat_name=$aaron_name
	if [ -d $all_packages_path/$tomcat_name ]; then
		# 拷贝修改权限
		if [ -d $insatll_path/$tomcat_name ]; then
			echo -e "\033[32m$insatll_path/$tomcat_name 已经存在\033[0m"
		else
			echo -e "\033[32m开始拷贝$tomcat_name到$insatll_path 请等待...\033[0m"
			echo "123456"|sudo -s cp -r $all_packages_path/$tomcat_name $insatll_path
			echo "123456"|sudo -s chmod -R 777 $insatll_path/$tomcat_name
			echo "123456"|sudo -s chown -R yuantiaotech:yuantiaotech $insatll_path/$tomcat_name
		fi

		echo -e "\033[32m开始文件配置，请等待...\033[0m"
		sleep 1

		# 配置第一个数据库及IP
		# 获取原文件camo数据库名称
		catFile=`cat $filePath_tomcat | grep url`
		aaa=${catFile%%\?*}
		firstDbName=${aaa##*/}
		file_DbName=$firstDbName
		configAaronDbAndIP
		sleep 1

		# 配置第二个数据库及IP
		# 获取原文件aaron数据库名称
		bbb=${catFile%\?*}
		secondDbName=${bbb##*/}
		file_DbName=$secondDbName
		configAaronDbAndIP

		# 配置端口
		configPort_filePath=$filePath_tomcatPort
		configTomcatPort

		# 编写conf文件
		configSupervisorConf
	else
		echo -e "\033[31m错误：$tomcat_name不存在，先将文件夹拷贝至$all_packages_path路径下！\033[0m"
	fi	
}

# 配置aaron的配置文件
configAaronDbAndIP(){
	cat2File=`cat $filePath_tomcat | grep $file_DbName`
	#获取指定字符串的行号
	line=`sed -n '/'$(echo $file_DbName)'/=' $filePath_tomcat`
	# 判断第一个数据库名称
	if [[ "$file_DbName" =~ camo.* ]]; then
		echo -e "\033[32m将数据库$file_DbName 修改为$camo_db_name，IP修改为$camo_IP_database\033[0m"
		newInfo=\\${cat2File%%//*}//${camo_IP_database}:3306/${camo_db_name}?${cat2File##*\?}
		# 删除这行,插入新字符串
		sed -i "$line d" $filePath_tomcat
		sed -i "$line i$newInfo" $filePath_tomcat
	else
		echo -e "\033[32m将数据库：$file_DbName 修改为$aaron_db_name，IP修改为$aaron_IP_database\033[0m"
		newInfo=\\${cat2File%%//*}//${aaron_IP_database}:3306/${aaron_db_name}?${cat2File##*\?}
		# 删除这行,插入新字符串
		sed -i "$line d" $filePath_tomcat
		sed -i "$line i$newInfo" $filePath_tomcat
	fi
}

# 修改tomcat端口前区分aaron及geoLayer
configTomcatPort(){
	# 修改端口
	# shutdown端口
	catShutdownPort=`cat $configPort_filePath | grep "<Server port=\"....\" shutdown=\"SHUTDOWN\">"`
	cat_port=$catShutdownPort
	port_name=Shutdown
	if [ "$tomcat_name" == "$aaron_name" ]; then
		port_no=$aaron_shutdownPort
	else
		port_no=$geo_shutdownPort
	fi
	configPort

	# http端口
	catHTTPPort=`cat $configPort_filePath | grep "<Connector connectionTimeout=\"20000\" port=\"....\" protocol=\"HTTP/1.1\" redirectPort=\"....\"/>"`
	cat_port=$catHTTPPort
	port_name=HTTP
	if [ "$tomcat_name" == "$aaron_name" ]; then
		port_no=$aaron_httpPort
	else
		port_no=$geo_httpPort
	fi
	configPort

	# redirect端口，不修改
	ggg=${catHTTPPort#*redirectPort=\"}
	redirectPort=${ggg%%\"*}

	# AJP端口
	catAjpPort=`cat $configPort_filePath | grep "<Connector port=\"....\" protocol=\"AJP/1.3\" redirectPort=\"....\"/>"`
	cat_port=$catAjpPort
	port_name=AJP
	if [ "$tomcat_name" == "$aaron_name" ]; then
		port_no=$aaron_ajpPort
	else
		port_no=$geo_ajpPort
	fi
	configPort
}

# 修改tomcat端口
configPort(){
	hhh=${cat_port#*port=\"}
	port=${hhh%%\"*}
	if [ "$port" == "$port_no" ]; then
		echo -e "\033[32mtomcat的$port_name端口已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $port)'/'$(echo $port_no)'/g' $configPort_filePath
		if [ $? -eq 0 ]; then
			echo -e "\033[32mtomcat的$port_name端口配置成功\033[0m"
		else
			echo -e "\033[31mtomcat的$port_name端口配置失败\033[0m"
		fi
	fi
}

# ================================================================ tomcat_geoLayer配置 ================================================================
configTomcatGeo(){
	tomcat_name=$geoLayer_name
	if [ -d $all_packages_path/$tomcat_name ]; then
		# 拷贝修改权限
		if [ -d $insatll_path/$tomcat_name ]; then
			echo -e "\033[32m$insatll_path/$tomcat_name 已经存在\033[0m"
		else
			echo -e "\033[32m开始拷贝$geoLayer_name到$insatll_path 请等待...\033[0m"
			echo "123456"|sudo -s cp -r $all_packages_path/$tomcat_name $insatll_path
			echo "123456"|sudo -s chmod -R 777 $insatll_path/$tomcat_name
		fi
		
		echo -e "\033[32m开始文件配置，请等待...\033[0m"
		sleep 1
		
		# 配置camo信息
		search_keyword=host
		db_or_ip=$camo_IP_database
		filePath_geoLayer=$filePath_geoCamo
		configGeoDbAndIP

		search_keyword=database
		db_or_ip=$camo_db_name
		configGeoDbAndIP

		# 配置aaron信息
		search_keyword=host
		db_or_ip=$aaron_IP_database
		filePath_geoLayer=$filePath_geoAaron
		configGeoDbAndIP

		search_keyword=database
		db_or_ip=$aaron_db_name
		configGeoDbAndIP
		
		# 配置端口
		configPort_filePath=$filePath_geoPort
		configTomcatPort
		
		# 编写conf文件
		configSupervisorConf
	else
		echo -e "\033[31m错误：$geoLayer_name不存在，先将文件夹拷贝至$all_packages_path路径下！\033[0m"
	fi
}

# 配置tomcat_geoLayer的文件
configGeoDbAndIP(){
	# 截取文件
	catGeoInfo=`cat $filePath_geoLayer | grep $search_keyword`
	# 获取原文件camo数据库IP
	eee=${catGeoInfo#*>}
	geoInfo=${eee%%<*}
	if [ "$geoInfo" == "$db_or_ip" ]; then
		echo -e "\033[32mtomcat_geoLayer的已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $geoInfo)'/'$(echo $db_or_ip)'/g' $filePath_geoLayer
		if [ $? -eq 0 ]; then
			echo -e "\033[32mtomcat_geoLayer将$geoInfo 修改为$db_or_ip配置成功\033[0m"
		else
			echo -e "\033[31mtomcat_geoLayer将$geoInfo 修改为$db_or_ip配置失败\033[0m"
		fi
	fi
}

# 创建.conf文件
configSupervisorConf(){
	if [ -d /etc/supervisor/conf.d/$tomcat_name.conf ]; then
		echo -e "\033[32m$tomcat_name.conf已经存在\033[0m"
	else
		echo "123456"|sudo -s su - root -c "echo "[program:$tomcat_name]" >> $insatll_path/$tomcat_name.conf"
		echo "123456"|sudo -s sed -i '$acommand='$(echo $insatll_path)'/'$(echo $tomcat_name)'/bin/catalina.sh run' $insatll_path/$tomcat_name.conf
		echo "123456"|sudo -s sed -i '$adirectory='$(echo $insatll_path)'/'$(echo $tomcat_name)'/bin' $insatll_path/$tomcat_name.conf
		echo "123456"|sudo -s sed -i '$aautorestart=true' $insatll_path/$tomcat_name.conf
		echo "123456"|sudo -s sed -i '$auser=yuantiaotech' $insatll_path/$tomcat_name.conf
		echo "123456"|sudo -s sed -i '$aautostart=true' $insatll_path/$tomcat_name.conf
		echo "123456"|sudo -s sed -i '$astdout_logfile='$(echo $insatll_path)'/'$(echo $tomcat_name)'/logs/catalina.out' $insatll_path/$tomcat_name.conf
		echo "123456"|sudo -s sed -i '$aredirect_stderr=true' $insatll_path/$tomcat_name.conf
		echo "123456"|sudo -s sed -i '$astdout_logfile_maxbytes=100MB' $insatll_path/$tomcat_name.conf
		echo "123456"|sudo -s sed -i '$astdout_logfile_backups=10' $insatll_path/$tomcat_name.conf

		echo "123456"|sudo -s chmod -R 755 $insatll_path/$tomcat_name.conf
		echo "123456"|sudo -s mv $insatll_path/$tomcat_name.conf /etc/supervisor/conf.d/
		if [ $? -eq 0 ]; then
			echo -e "\033[32m$tomcat_name的$tomcat_name.conf创建成功\033[0m"
		else
			echo -e "\033[31m$tomcat_name的$tomcat_name.conf创建失败\033[0m"
		fi
	fi
}

# 检查安装路径是否存在，不存在则创建
checkInstallPath(){
	# 检查路径
	if [ ! -d $insatll_path ]; then
	    mkdir $insatll_path
	    if [ $? -eq 0 ]; then
			echo -e "\033[32m$insatll_path 路径创建成功\033[0m"
		else
			echo -e "\033[31m$insatll_path 路径创建失败\033[0m"
			exit 0
		fi
	else
	    echo -e "\033[32m$insatll_path 路径已经存在\033[0m"
	fi
}

# ================================================================ 主函数 ================================================================
menu(){
	checkInstallPath
	configTomcatAaron
	configTomcatGeo
}
menu