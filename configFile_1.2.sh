#!/bin/bash

# 文 件 名 : configFile_1.2.sh
# 作    者 : 沈喆
# 版    本 : 1.1
# 更新时间 : 2018/01/26
# 描    述 : 本脚本用于在态势1.2部署过程中对解压后的indexmonitor进行相应的配置，该脚本需要在war包解压后运行。

# 手动修改
city_new=杭州市															# 城市名称
IP_new=192.168.0.12														# 数据库服务器IP
dataserverIP=192.168.0.12												# dataserver部署服务器IP
database=hangzhou														# boomy数据库名称
indexdatabase=indexmonitor_hangzhou										# 应用数据库名称
mapURL=http://192.168.0.12:8090/iserver/services/luan/rest/maps/luan	# 地图URL
warPath=/home/yuantiaotech/tomcat_index/webapps/indexmonitor			# war包所在路径，参照示例书写
lon=192.2222															# 地图中心点经度
lat=31.2222																# 地图中心点纬度
# -----------------------------------------------------------------------------------------------------------------------------

# 修改城市名
aaa=`cat $warPath/WEB-INF/classes/area.xml | grep city`
bbb=${aaa##*=}
ccc=${bbb#*\"}
ddd=${ccc%\"*}
city_old=$ddd

echo "文件原城市:$city_old"
sed -i 's/'$(echo $city_old)'/'$(echo $city_new)'/g' $warPath/WEB-INF/classes/area.xml
sed -i 's/'$(echo $city_old)'/'$(echo $city_new)'/g' $warPath/screen/Pages/stateMonitorPage/config/bar/aAreaRediusBar.json
sed -i 's/'$(echo $city_old)'/'$(echo $city_new)'/g' $warPath/screen/Pages/stateMonitorPage/config/bar/iAreaRediusBar.json
sed -i 's/'$(echo $city_old)'/'$(echo $city_new)'/g' $warPath/screen/Pages/stateMonitorPage/config/bar/iRoadRediusBar.json
sed -i 's/'$(echo $city_old)'/'$(echo $city_new)'/g' $warPath/screen/Pages/stateMonitorPage/config/line/lineGradient.json
sed -i 's/'$(echo $city_old)'/'$(echo $city_new)'/g' $warPath/screen/Pages/stateMonitorPage/config/list/rankList.json

# 修改IP地址
eee=`cat $warPath/WEB-INF/classes/database.xml | grep url`
#echo "$eee"

fff=${eee#*//}
ggg=${fff%%:*}
echo "文件原IP:$ggg"
IP_old=$ggg

sed -i 's/'$(echo $IP_old)'/'$(echo $IP_new)'/g' $warPath/WEB-INF/classes/database.xml
sed -i 's/'$(echo $IP_old)'/'$(echo $IP_new)'/g' $warPath/WEB-INF/classes/dbservice.properties
sed -i 's/'$(echo $IP_old)'/'$(echo $IP_new)'/g' $warPath/WEB-INF/classes/jdbc.properties
sed -i 's/'$(echo $IP_old)'/'$(echo $IP_new)'/g' $warPath/WEB-INF/classes/rbac.properties

# 修改数据库名
hhh=`cat $warPath/WEB-INF/classes/database.xml | grep dbname`
iii=${hhh#*>}
jjj=${iii%%<*}
echo "文件原boomy数据库:$jjj"
database_old=$jjj
kkk=${hhh%<*}
lll=${kkk##*>}
echo "文件原应用数据库:$lll"
indexdatabase_old=$lll

sed -i 's/'$(echo $database_old)'/'$(echo $database)'/g' $warPath/WEB-INF/classes/database.xml
sed -i 's/'$(echo $indexdatabase_old)'/'$(echo $indexdatabase)'/g' $warPath/WEB-INF/classes/database.xml
sed -i 's/'$(echo $database_old)'/'$(echo $dataserverIP)'/g' $warPath/WEB-INF/classes/dbservice.properties
sed -i 's/'$(echo $database_old)'/'$(echo $database)'/g' $warPath/WEB-INF/classes/jdbc.properties
sed -i 's/'$(echo $indexdatabase_old)'/'$(echo $indexdatabase)'/g' $warPath/WEB-INF/classes/jdbc.properties
sed -i 's/'$(echo $indexdatabase_old)'/'$(echo $indexdatabase)'/g' $warPath/WEB-INF/classes/rbac.properties

# 修改地图
mmm=`cat $warPath/WEB-INF/ui/config/mapconfig.json | grep mapurl`
nnn=${mmm%\"*}
ooo=${nnn##*\"}
echo "文件原地图URL:$ooo"
mapURL_old=$ooo

sed -i 's|'$(echo $mapURL_old)'|'$(echo $mapURL)'|g' $warPath/WEB-INF/ui/config/mapconfig.json

# 修改地图中心点
ppp=`cat $warPath/WEB-INF/ui/config/mapconfig.json | grep center`
qqq=${ppp%%,*}
rrr=${qqq##*:}
lon_old=$rrr

sss=${ppp##*:}
ttt=${sss%\}*} 
lat_old=$ttt
echo "文件原地图中心点($lon_old,$lat_old)"

sed -i 's|'$(echo $lat_old)'|'$(echo $lat)'|g' $warPath/WEB-INF/ui/config/mapconfig.json
sed -i 's|'$(echo $lon_old)'|'$(echo $lon)'|g' $warPath/WEB-INF/ui/config/mapconfig.json
