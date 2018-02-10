#!/bin/bash

# 文 件 名 : configFile_2.0.sh
# 作    者 : 沈喆
# 版    本 : 1.1
# 更新时间 : 2018/01/31
# 描    述 : 本脚本用于在态势2.0部署过程中对两个tomcat进行相应的配置。
# 			 一般将tomcat都部署在/home/yuantiaotech/project/index目录下。

# -------------------------------------------------------------- 手动修改 --------------------------------------------------------------
camo_IP_database=192.168.0.112			# 大数据camo数据库服务器IP
aaron_IP_database=$camo_IP_database		# 应用aaron数据库服务器IP，一般情况下与大数据camo数据库服务器IP相同
camo_db_name=camo1.1.1.2				# 大数据camo数据库名称
aaron_db_name=aaron1.1.1.2				# 应用aaron数据库名称

# -------------------------------------------------------------- 脚本环境变量 --------------------------------------------------------------
all_packages_path=/tmp					# 安装包默认放置路径，所有安装包都会到这个路径下去读取
tomcat_name=tomcat_aaron         		# tomcat文件夹名称
geoLayer_name=tomcat_geoLayer			# geoserver文件夹名称
insatll_path=/home/yuantiaotech			# 安装路径
# tomcat配置文件路径
filePath_tomcat=$insatll_path/$tomcat_name/webapps/pf.web.runtime/configuration/datasource.xml
# geoserver配置文件路径
filePath_geoCamo=$insatll_path/$geoLayer_name/webapps/geoserver/data/workspaces/cite/qj/datastore.xml
filePath_geoAaron=$insatll_path/$geoLayer_name/webapps/geoserver/data/workspaces/cite/wx/datastore.xml
# tomcat 端口配置路径
filePath_tomcatPort=$insatll_path/$tomcat_name/conf/server.xml
# geoLayer 端口配置路径
filePath_geoPort=$insatll_path/$geoLayer_name/conf/server.xml
# tomcat 端口
shutdown_portTomcat=8021
http_portTomcat=8388
ajp_portTomcat=8033
# tomcat_geoLayer 端口
shutdown_portGeo=8227
http_portGeo=8385
ajp_portGeo=9395

file_path=0 # tomcat的server.xml路径
file_DbName=0 # 临时保存文件中数据库名称
cat_port=0 # 临时保存截取端口的内容
port_name=0 # 临时保存端口名称
port_no=0 # 临时保存端口号

# ================================================================ tomcat_aaron配置 ================================================================
configTomcat(){
	if [ -d $all_packages_path/$tomcat_name ]; then
		# 拷贝修改权限
		if [ -d $insatll_path/$tomcat_name ]; then
			echo -e "\033[32m$insatll_path/$tomcat_name 已经存在\033[0m"
		else
			echo -e "\033[32m开始拷贝$tomcat_name到$insatll_path 请等待...\033[0m"
			echo "123456"|sudo -s cp -r $all_packages_path/$tomcat_name $insatll_path
			echo "123456"|sudo -s chmod -R 777 $insatll_path/$tomcat_name
		fi

		echo -e "\033[32m开始文件配置，请等待...\033[0m"
		sleep 1

		# 配置第一个数据库及IP
		# 获取原文件camo数据库名称
		catFile=`cat $filePath_tomcat | grep url`
		aaa=${catFile%%\?*}
		firstDbName=${aaa##*/}
		file_DbName=$firstDbName
		configTomcatDbAndIP
		sleep 1

		# 配置第二个数据库及IP
		# 获取原文件aaron数据库名称
		#catFile=`cat $filePath_tomcat | grep url`
		bbb=${catFile%\?*}
		secondDbName=${bbb##*/}
		file_DbName=$secondDbName
		configTomcatDbAndIP

		file_path=$filePath_tomcatPort
		configTomcatPort
		
	else
		echo -e "\033[31m错误：$tomcat_name不存在，先将文件夹拷贝至$all_packages_path路径下！\033[0m"
	fi	
}

configTomcatDbAndIP(){
	cat2File=`cat $filePath_tomcat | grep $file_DbName`
	#获取指定字符串的行号
	line=`sed -n '/'$(echo $file_DbName)'/=' $filePath_tomcat`
	# 判断第一个数据库名称
	if [[ "$file_DbName" =~ camo.* ]]; then
		echo -e "\033[32m将数据库：$file_DbName 修改为：$camo_db_name，IP修改为：$camo_IP_database\033[0m"
		newInfo=\\${cat2File%%//*}//${camo_IP_database}:3306/${camo_db_name}?${cat2File##*\?}
		# 删除这行,插入新字符串
		sed -i "$line d" $filePath_tomcat
		sed -i "$line i$newInfo" $filePath_tomcat
	else
		echo -e "\033[32m将数据库：$file_DbName 修改为：$aaron_db_name，IP修改为：$aaron_IP_database\033[0m"
		newInfo=\\${cat2File%%//*}//${aaron_IP_database}:3306/${aaron_db_name}?${cat2File##*\?}
		# 删除这行,插入新字符串
		sed -i "$line d" $filePath_tomcat
		sed -i "$line i$newInfo" $filePath_tomcat
	fi
}

configTomcatPort(){
	# 修改端口
	# shutdown端口
	catShutdownPort=`cat $file_path | grep "<Server port=\"....\" shutdown=\"SHUTDOWN\">"`
	cat_port=$catShutdownPort
	port_name=Shutdown
	port_no=$shutdown_portTomcat
	configPort

	# http端口
	catHTTPPort=`cat $file_path | grep "<Connector connectionTimeout=\"20000\" port=\"....\" protocol=\"HTTP/1.1\" redirectPort=\"....\"/>"`
	cat_port=$catHTTPPort
	port_name=HTTP
	port_no=$http_portTomcat
	configPort

	# redirect端口
	ggg=${catHTTPPort#*redirectPort=\"}
	redirectPort=${ggg%%\"*}

	# AJP端口
	catAjpPort=`cat $file_path | grep "<Connector port=\"....\" protocol=\"AJP/1.3\" redirectPort=\"....\"/>"`
	cat_port=$catAjpPort
	port_name=AJP
	port_no=$ajp_portTomcat
	configPort

}

configPort(){
	hhh=${cat_port#*port=\"}
	port=${hhh%%\"*}
	if [ "$port" == "$portNo" ]; then
		echo -e "\033[32mtomcat的$portName端口已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $port)'/'$(echo $portNo)'/g' $file_path
		if [ $? -eq 0 ]; then
			echo -e "\033[32mtomcat的$portName端口配置成功\033[0m"
		else
			echo -e "\033[31mtomcat的$portName端口配置失败\033[0m"
		fi
	fi
}


# ================================================================ tomcat_geoLayer配置 ================================================================
configTomcatGeo(){
	if [ -d $all_packages_path/$geoLayer_name ]; then
		# 拷贝修改权限
		if [ -d $insatll_path/$geoLayer_name ]; then
			echo -e "\033[32m$insatll_path/$geoLayer_name 已经存在\033[0m"
		else
			echo -e "\033[32m开始拷贝$geoLayer_name到$insatll_path 请等待...\033[0m"
			echo "123456"|sudo -s cp -r $all_packages_path/$geoLayer_name $insatll_path
			echo "123456"|sudo -s chmod -R 777 $insatll_path/$geoLayer_name
		fi
		
		echo -e "\033[32m开始文件配置，请等待...\033[0m"
		sleep 1
		
		# 截取文件
		catGeoCamoIP=`cat $filePath_geoCamo | grep host`
		# 获取原文件camo数据库IP
		eee=${catGeoCamoIP#*>}
		geoCamoIP=${eee%%<*}
		if [ "$geoCamoIP" == "$camo_IP_database" ]; then
			echo -e "\033[32mgeoserver的camo数据库IP已经配置\033[0m"
		else
			echo "123456"|sudo -s sed -i 's/'$(echo $geoCamoIP)'/'$(echo $camo_IP_database)'/g' $filePath_geoCamo
			if [ $? -eq 0 ]; then
				echo -e "\033[32mgeoserver的camo数据库IP配置成功\033[0m"
			else
				echo -e "\033[31mgeoserver的camo数据库IP配置失败\033[0m"
			fi
		fi

		# 截取文件
		catGeoCamoDb=`cat $filePath_geoCamo | grep database`
		# 获取原文件camo数据库名称
		fff=${catGeoCamoDb#*>}
		geoCamoDbName=${fff%%<*}
		if [ "$geoCamoDbName" == "$camo_db_name" ]; then
			echo -e "\033[32mgeoserver的camo数据库名称已经配置\033[0m"
		else
			echo "123456"|sudo -s sed -i 's/'$(echo $geoCamoDbName)'/'$(echo $camo_db_name)'/g' $filePath_geoCamo
			if [ $? -eq 0 ]; then
				echo -e "\033[32mgeoserver的camo数据库名称配置成功\033[0m"
			else
				echo -e "\033[31mgeoserver的camo数据库名称配置失败\033[0m"
			fi
		fi

		# 截取文件
		catGeoAaronIP=`cat $filePath_geoAaron | grep host`
		# 获取原文件aaron数据库IP
		ggg=${catGeoAaronIP#*>}
		geoAaronIP=${ggg%%<*}
		if [ "$geoAaronIP" == "$aaron_IP_database" ]; then
			echo -e "\033[32mgeoserver的aaron数据库IP已经配置\033[0m"
		else
			echo "123456"|sudo -s sed -i 's/'$(echo $geoAaronIP)'/'$(echo $aaron_IP_database)'/g' $filePath_geoAaron
			if [ $? -eq 0 ]; then
				echo -e "\033[32mgeoserver的aaron数据库IP配置成功\033[0m"
			else
				echo -e "\033[31mgeoserver的aaron数据库IP配置失败\033[0m"
			fi
		fi

		# 截取文件
		catGeoAaronDb=`cat $filePath_geoAaron | grep database`
		# 获取原文件aaron数据库IP
		hhh=${catGeoAaronDb#*>}
		geoAaronDbName=${hhh%%<*}
		if [ "$geoAaronDbName" == "$aaron_db_name" ]; then
			echo -e "\033[32mgeoserver的aaron数据库名称已经配置\033[0m"
		else
			echo "123456"|sudo -s sed -i 's/'$(echo $geoAaronDbName)'/'$(echo $aaron_db_name)'/g' $filePath_geoAaron
			if [ $? -eq 0 ]; then
				echo -e "\033[32mgeoserver的aaron数据库名称配置成功\033[0m"
			else
				echo -e "\033[31mgeoserver的aaron数据库名称配置失败\033[0m"
			fi
		fi

		file_path=$filePath_geoPort
		configTomcatPort
		
	else
		echo -e "\033[31m错误：$geoLayer_name不存在，先将文件夹拷贝至$all_packages_path路径下！\033[0m"
	fi
}

# ================================================================ 主函数 ================================================================
menu(){
	configTomcat
	configTomcatGeo
}
menu