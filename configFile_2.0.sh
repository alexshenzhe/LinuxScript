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

# ================================================================ tomcat_aaron配置 ================================================================
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
	# 截取文件
	catFile=`cat $filePath_tomcat | grep url`

	# 获取原文件camo数据库名称
	bbb=${catFile%%\?*}
	firstDbName=${bbb##*/}

	cat2File=`cat $filePath_tomcat | grep $firstDbName`
	
	#获取指定字符串的行号
	line=`sed -n '/'$(echo $firstDbName)'/=' $filePath_tomcat`

	# 判断第一个数据库名称
	if [[ "$firstDbName" =~ camo.* ]]; then
		newInfo=\\${cat2File%%//*}//${camo_IP_database}:3306/${camo_db_name}?${cat2File##*\?}
		# 删除这行,插入新字符串
		sed -i "$line d" $filePath_tomcat
		sed -i "$line i$newInfo" $filePath_tomcat
	else
		newInfo=\\${cat2File%%//*}//${aaron_IP_database}:3306/${aaron_db_name}?${cat2File##*\?}
		# 删除这行,插入新字符串
		sed -i "$line d" $filePath_tomcat
		sed -i "$line i$newInfo" $filePath_tomcat
	fi

	# 重新截取文件
	catFile=`cat $filePath_tomcat | grep url`
	# 获取原文件aaron数据库名称
	ddd=${catFile%\?*}
	secondDbName=${ddd##*/}

	cat3File=`cat $filePath_tomcat | grep $secondDbName`
	#获取指定字符串的行号
	line2=`sed -n '/'$(echo $secondDbName)'/=' $filePath_tomcat`

	# 判断第二个数据库名称
	if [[ "$secondDbName" =~ camo.* ]]; then
		newInfo=\\${cat3File%%//*}//${camo_IP_database}:3306/${camo_db_name}?${cat3File##*\?}
		# 删除这行,插入新字符串
		sed -i "$line2 d" $filePath_tomcat
		sed -i "$line2 i$newInfo" $filePath_tomcat

	else
		newInfo=\\${cat3File%%//*}//${aaron_IP_database}:3306/${aaron_db_name}?${cat3File##*\?}
		# 删除这行,插入新字符串
		sed -i "$line2 d" $filePath_tomcat
		sed -i "$line2 i$newInfo" $filePath_tomcat
	fi


	# 修改端口
	# shutdown端口
	catShutdownPort=`cat $filePath_tomcatPort | grep "<Server port=\"....\" shutdown=\"SHUTDOWN\">"`
	eee=${catShutdownPort#*\"}
	shutdownPort=${eee%%\"*}
	if [ "$shutdownPort" == "$shutdown_portTomcat" ]; then
		echo -e "\033[32mtomcat的SHUTDOWN端口已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $shutdownPort)'/'$(echo $shutdown_portTomcat)'/g' $filePath_tomcatPort
		if [ $? -eq 0 ]; then
			echo -e "\033[32mtomcat的SHUTDOWN端口配置成功\033[0m"
		else
			echo -e "\033[31mtomcat的SHUTDOWN端口配置失败\033[0m"
		fi
	fi

	# http端口
	catHTTPPort=`cat $filePath_tomcatPort | grep "<Connector connectionTimeout=\"20000\" port=\"....\" protocol=\"HTTP/1.1\" redirectPort=\"....\"/>"`
	fff=${catHTTPPort#*port=\"}
	HTTPPort=${fff%%\"*}
	if [ "$HTTPPort" == "$http_portTomcat" ]; then
		echo -e "\033[32mtomcat的HTTP端口已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $HTTPPort)'/'$(echo $http_portTomcat)'/g' $filePath_tomcatPort
		if [ $? -eq 0 ]; then
			echo -e "\033[32mtomcat的HTTP端口配置成功\033[0m"
		else
			echo -e "\033[31mtomcat的HTTP端口配置失败\033[0m"
		fi
	fi

	# redirect端口
	ggg=${catHTTPPort#*redirectPort=\"}
	redirectPort=${ggg%%\"*}

	# AJP端口
	catAjpPort=`cat $filePath_tomcatPort | grep "<Connector port=\"....\" protocol=\"AJP/1.3\" redirectPort=\"....\"/>"`
	hhh=${catAjpPort#*port=\"}
	AJPPort=${hhh%%\"*}
	if [ "$AJPPort" == "$ajp_portTomcat" ]; then
		echo -e "\033[32mtomcat的AJP端口已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $AJPPort)'/'$(echo $ajp_portTomcat)'/g' $filePath_tomcatPort
		if [ $? -eq 0 ]; then
			echo -e "\033[32mtomcat的AJP端口配置成功\033[0m"
		else
			echo -e "\033[31mtomcat的AJP端口配置失败\033[0m"
		fi
	fi
else
	echo -e "\033[31m错误：$tomcat_name不存在，先将文件夹拷贝至$all_packages_path路径下！\033[0m"
fi

# ================================================================ tomcat_geoLayer配置 ================================================================
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

	# 修改端口
	# shutdown端口
	catShutdownPort=`cat $filePath_geoPort | grep "<Server port=\"....\" shutdown=\"SHUTDOWN\">"`
	eee=${catShutdownPort#*\"}
	shutdownPort=${eee%%\"*}
	if [ "$shutdownPort" == "$shutdown_portGeo" ]; then
		echo -e "\033[32mtomcat的SHUTDOWN端口已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $shutdownPort)'/'$(echo $shutdown_portGeo)'/g' $filePath_geoPort
		if [ $? -eq 0  ]; then
			echo -e "\033[32mtomcat的SHUTDOWN端口配置成功\033[0m"
		else
			echo -e "\033[31mtomcat的SHUTDOWN端口配置失败\033[0m"
		fi
	fi

	# http端口
	catHTTPPort=`cat $filePath_geoPort | grep "<Connector connectionTimeout=\"20000\" port=\"....\" protocol=\"HTTP/1.1\" redirectPort=\"....\"/>"`
	fff=${catHTTPPort#*port=\"}
	HTTPPort=${fff%%\"*}
	if [ "$HTTPPort" == "$http_portGeo" ]; then
		echo -e "\033[32mtomcat的HTTP端口已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $HTTPPort)'/'$(echo $http_portGeo)'/g' $filePath_geoPort
		if [ $? -eq 0 ]; then
			echo -e "\033[32mtomcat的HTTP端口配置成功\033[0m"
		else
			echo -e "\033[31mtomcat的HTTP端口配置失败\033[0m"
		fi
	fi

	#redirect端口
	ggg=${catHTTPPort#*redirectPort=\"}
	redirectPort=${ggg%%\"*}

	# AJP端口
	catAjpPort=`cat $filePath_geoPort | grep "<Connector port=\"....\" protocol=\"AJP/1.3\" redirectPort=\"....\"/>"`
	hhh=${catAjpPort#*port=\"}
	AJPPort=${hhh%%\"*}
	if [ "$AJPPort" == "$ajp_portGeo" ]; then
		echo -e "\033[32mtomcat的AJP端口已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $AJPPort)'/'$(echo $ajp_portGeo)'/g' $filePath_geoPort
		if [ $? -eq 0 ]; then
			echo -e "\033[32mtomcat的AJP端口配置成功\033[0m"
		else
			echo -e "\033[31mtomcat的AJP端口配置失败\033[0m"
		fi
	fi
else
	echo -e "\033[31m错误：$geoLayer_name不存在，先将文件夹拷贝至$all_packages_path路径下！\033[0m"
fi