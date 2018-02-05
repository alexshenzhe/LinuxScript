#!/bin/bash

# 文 件 名 : configFile_2.0.sh
# 作    者 : 沈喆
# 版    本 : 1.1
# 更新时间 : 2018/01/31
# 描    述 : 本脚本用于在态势2.0部署过程中对两个tomcat进行相应的配置。
# 			 一般将tomcat都部署在/home/yuantiaotech/project/index目录下。

# 手动修改
camo_IP_database=192.168.0.112			# 大数据camo数据库服务器IP
aaron_IP_database=$camo_IP_database		# 应用aaron数据库服务器IP，一般情况下与大数据camo数据库服务器IP相同
camo_db_name=camo1.1.1.2				# 大数据camo数据库名称
aaron_db_name=aaron1.1.1.2				# 应用aaron数据库名称

# -----------------------------------------------------------------------------------------------------------------------------
# 脚本环境变量
all_packages_path=/tmp					# 安装包默认放置路径，所有安装包都会到这个路径下去读取
tomcat_name=apache-tomcat-aaron         # tomcat文件夹名称
geoserver_name=apache-tomcat-aarongeo	# geoserver文件夹名称
insatll_path=/home/yuantiaotech			# 安装路径
# tomcat配置文件路径
filePath=$insatll_path/$tomcat_name/webapps/pf.web.runtime/configuration/datasource.xml
# geoserver配置文件路径
filePathGeoCamo=$insatll_path/$geoserver_name/webapps/geoserver/data/workspaces/cite/qj/datastore.xml
filePathGeoAaron=$insatll_path/$geoserver_name/webapps/geoserver/data/workspaces/cite/wx/datastore.xml

# ================================================================ tomcat_aaron配置 ================================================================
if [ -d $all_packages_path/$tomcat_name ]; then
	# 拷贝修改权限
	if [ -d $insatll_path/$tomcat_name ]; then
		echo -e "\033[32m$insatll_path/$tomcat_name 已经存在\033[0m"
	else
		echo -e "\033[32m开始拷贝ls$tomcat_name到$insatll_path 请等待...\033[0m"
		echo "123456"|sudo -s cp -r $all_packages_path/$tomcat_name $insatll_path
		echo "123456"|sudo -s chmod -R 777 $insatll_path/$tomcat_name
	fi


	echo -e "\033[32m开始文件配置，请等待...\033[0m"
	sleep 1
	# 截取文件
	catFile=`cat $filePath | grep url`

	# 获取原文件camo数据库IP
	aaa=${catFile#*//}
	camoIP=${aaa%%:*}
	if [ "$camoIP" == "$camo_IP_database" ]; then
		echo -e "\033[32mtomcat的camo数据库IP已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $camoIP)'/'$(echo $camo_IP_database)'/g' $filePath
		if [ $? -eq 0  ]; then
			echo -e "\033[32mtomcat的camo数据库IP配置成功\033[0m"
		else
			echo -e "\033[31mtomcat的camo数据库IP配置失败\033[0m"
		fi
	fi

	# 获取原文件camo数据库名称
	bbb=${catFile%%\?*}
	camoDbName=${bbb##*/}
	if [ "$camoDbName" == "$camo_db_name" ]; then
		echo -e "\033[32mtomcat的camo数据库名称已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $camoDbName)'/'$(echo $camo_db_name)'/g' $filePath
		if [ $? -eq 0  ]; then
			echo -e "\033[32mtomcat的camo数据库名称配置成功\033[0m"
		else
			echo -e "\033[31mtomcat的camo数据库名称配置失败\033[0m"
		fi
	fi

	# 获取原文件aaron数据库IP
	ccc=${catFile##*//}
	aaronIP=${ccc%%:*}
	if [ "$aaronIP" == "$aaron_IP_database" ]; then
		echo -e "\033[32mtomcat的aaron数据库IP已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $aaronIP)'/'$(echo $aaron_IP_database)'/g' $filePath
		if [ $? -eq 0  ]; then
			echo -e "\033[32mtomcat的aaron数据库IP配置成功\033[0m"
		else
			echo -e "\033[31mtomcat的aaron数据库IP配置失败\033[0m"
		fi
	fi

	# 获取原文件aaron数据库名称
	ddd=${catFile%\?*}
	aaronDbName=${ddd##*/}
	if [ "$aaronDbName" == "$aaron_db_name" ]; then
		echo -e "\033[32mtomcat的aaron数据库名称已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $aaronDbName)'/'$(echo $aaron_db_name)'/g' $filePath
		if [ $? -eq 0  ]; then
			echo -e "\033[32mtomcat的aaron数据库名称配置成功\033[0m"
		else
			echo -e "\033[31mtomcat的aaron数据库名称配置失败\033[0m"
		fi
	fi	
else
	echo -e "\033[31m错误：$tomcat_name不存在，先将文件夹拷贝至$all_packages_path路径下！\033[0m"
fi

# ================================================================ tomcat_geoLayer配置 ================================================================
if [ -d $all_packages_path/$geoserver_name ]; then
	# 拷贝修改权限
	if [ -d $insatll_path/$geoserver_name ]; then
		echo -e "\033[32m$insatll_path/$geoserver_name 已经存在\033[0m"
	else
		echo -e "\033[32m开始拷贝$geoserver_name到$insatll_path 请等待...\033[0m"
		echo "123456"|sudo -s cp -r $all_packages_path/$geoserver_name $insatll_path
		echo "123456"|sudo -s chmod -R 777 $insatll_path/$geoserver_name
	fi
	
	echo -e "\033[32m开始文件配置，请等待...\033[0m"
	sleep 1
	# 截取文件
	catGeoCamoIP=`cat $filePathGeoCamo | grep host`
	# 获取原文件camo数据库IP
	eee=${catGeoCamoIP#*>}
	geoCamoIP=${eee%%<*}
	if [ "$geoCamoIP" == "$camo_IP_database" ]; then
		echo -e "\033[32mgeoserver的camo数据库IP已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $geoCamoIP)'/'$(echo $camo_IP_database)'/g' $filePathGeoCamo
		if [ $? -eq 0  ]; then
			echo -e "\033[32mgeoserver的camo数据库IP配置成功\033[0m"
		else
			echo -e "\033[31mgeoserver的camo数据库IP配置失败\033[0m"
		fi
	fi

	# 截取文件
	catGeoCamoDb=`cat $filePathGeoCamo | grep database`
	# 获取原文件camo数据库名称
	fff=${catGeoCamoDb#*>}
	geoCamoDbName=${fff%%<*}
	if [ "$geoCamoDbName" == "$camo_db_name" ]; then
		echo -e "\033[32mgeoserver的camo数据库名称已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $geoCamoDbName)'/'$(echo $camo_db_name)'/g' $filePathGeoCamo
		if [ $? -eq 0  ]; then
			echo -e "\033[32mgeoserver的camo数据库名称配置成功\033[0m"
		else
			echo -e "\033[31mgeoserver的camo数据库名称配置失败\033[0m"
		fi
	fi

	# 截取文件
	catGeoAaronIP=`cat $filePathGeoAaron | grep host`
	# 获取原文件aaron数据库IP
	ggg=${catGeoAaronIP#*>}
	geoAaronIP=${ggg%%<*}
	if [ "$geoAaronIP" == "$aaron_IP_database" ]; then
		echo -e "\033[32mgeoserver的aaron数据库IP已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $geoAaronIP)'/'$(echo $aaron_IP_database)'/g' $filePathGeoAaron
		if [ $? -eq 0  ]; then
			echo -e "\033[32mgeoserver的aaron数据库IP配置成功\033[0m"
		else
			echo -e "\033[31mgeoserver的aaron数据库IP配置失败\033[0m"
		fi
	fi

	# 截取文件
	catGeoAaronDb=`cat $filePathGeoAaron | grep database`
	# 获取原文件aaron数据库IP
	hhh=${catGeoAaronDb#*>}
	geoAaronDbName=${hhh%%<*}
	if [ "$geoAaronDbName" == "$aaron_db_name" ]; then
		echo -e "\033[32mgeoserver的aaron数据库名称已经配置\033[0m"
	else
		echo "123456"|sudo -s sed -i 's/'$(echo $geoAaronDbName)'/'$(echo $aaron_db_name)'/g' $filePathGeoAaron
		if [ $? -eq 0  ]; then
			echo -e "\033[32mgeoserver的aaron数据库名称配置成功\033[0m"
		else
			echo -e "\033[31mgeoserver的aaron数据库名称配置失败\033[0m"
		fi
	fi
else
	echo -e "\033[31m错误：$geoserver_name不存在，先将文件夹拷贝至$all_packages_path路径下！\033[0m"
fi