#!/bin/sh

number=${2}

if [ ${number} == "1" ];then
echo '///-----------'
echo '/// 开始执行内测版本打包程序'
echo '///-----------'
elif [ ${number} == "2" ];then
echo '///-----------'
echo '/// 开始执行分发版本打包程序'
echo '///-----------'
else
echo '///-----------'
echo '/// 开始执行App Store打包程序'
echo '///-----------'
fi


#项目沙盒路径
project_sandBox_path=$(cd `dirname $0`; pwd)
#echo ${project_path}
#项目本地路径
project_path=${1}
#echo ${project_sandBox_path}
#plist文件所在路径
exportAdHocPlistPath=${project_sandBox_path}/exportAdHoc.plist
exportAppstorePlistPath=${project_sandBox_path}/exportAppstore.plist
exportEnterprisePlistPath=${project_sandBox_path}/exportEnterprise.plist

teamID=${3}

if [ "$teamID" =  "" ];
then
echo '///-----------'
echo '/// 请输入正确的teamID，否则无法打包成功'
echo '///-----------'
exit 0
fi

#添加
/usr/libexec/PlistBuddy -c "Set teamID $teamID" $exportAdHocPlistPath
/usr/libexec/PlistBuddy -c "Set teamID $teamID" $exportAppstorePlistPath
/usr/libexec/PlistBuddy -c "Set teamID $teamID" $exportEnterprisePlistPath

# cd到APP项目路径
cd ${project_path}

echo '///-----------'
echo '/// 检索是否存在工程项目'
echo '///-----------'

files=$(ls $project_path)
#echo $files
for filename in $files
do
#echo "filename: ${filename%.*}"
#echo ${filename##*.}

if [ ${filename##*.} == "xcworkspace" ];
then
#工程名
project_name=${filename%.*}
#scheme名
#scheme_name=${filename%.*}
scheme_name=${filename%.*}
echo ${filename##*.}
echo  ${filename%.*}
echo  ${filename}
fi
done

if [ "$project_name" =  "" ];
then
echo '///-----------'
echo '/// 未检索到xcworkspace项目，进程终止，请使用CocoaPods生成xcworkspace项目'
echo '///-----------'
exit 0
else
echo '///-----------'
echo '/// 已检索到工程项目'
echo '///-----------'
fi

echo '///-----------'
echo '/// 正在拷贝配置文件到APP工程目录'
echo '///-----------'
#拷贝文件到APP项目路径
cp -r ${exportAdHocPlistPath} ${project_path}
cp -r ${exportAppstorePlistPath} ${project_path}
cp -r ${exportEnterprisePlistPath} ${project_path}

#使用方法

if [ ! -d ./IPADir ];
then
mkdir -p IPADir;
fi

#打包模式 Debug/Release
development_mode=Debug

#build文件夹路径
build_path=${project_path}/build

#plist文件所在路径
exportOptionsPlistPath=${project_path}/exportAdHoc.plist

#导出.ipa文件所在路径
exportIpaPath=${project_path}/IPADir/${development_mode}

if [ ${number} == "1" ];then
echo '///-----------'
echo '/// 检测打包类型为内测'
echo '///-----------'
development_mode=Debug
exportOptionsPlistPath=${project_path}/exportAdHoc.plist
elif [ ${number} == "2" ];then
echo '///-----------'
echo '/// 检测打包类型为分发'
echo '///-----------'
development_mode=Debug
exportOptionsPlistPath=${project_path}/exportEnterprise.plist
else
echo '///-----------'
echo '/// 检测打包类型为App Store'
echo '///-----------'
development_mode=Release
exportOptionsPlistPath=${project_path}/exportAppstore.plist
fi


rm -rf ${project_path}/build

echo '///-----------'
echo '/// 正在清理工程'
echo '///-----------'
xcodebuild \
clean -configuration ${development_mode} -quiet  || exit

echo '///--------'
echo '/// 清理完成'
echo '///--------'
echo ''

echo '///-----------'
echo '/// 正在编译工程:'${development_mode}
echo '///-----------'
xcodebuild \
archive -workspace ${project_path}/${project_name}.xcworkspace \
-scheme ${scheme_name} \
-configuration ${development_mode} \
-archivePath ${build_path}/${project_name}.xcarchive  -quiet  || exit

echo '///--------'
echo '/// 编译完成'
echo '///--------'
echo ''

echo '///----------'
echo '/// 开始ipa打包'
echo '///----------'
xcodebuild -exportArchive -archivePath ${build_path}/${project_name}.xcarchive \
-configuration ${development_mode} \
-exportPath ${exportIpaPath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-quiet || exit

if [ -e $exportIpaPath/$scheme_name.ipa ]; then
echo '///----------'
echo '/// ipa包已导出'
echo '///----------'
#open $exportIpaPath
else
echo '///-------------'
echo '/// ipa包导出失败 '
echo '///-------------'
fi
echo '///------------'
echo '/// 打包ipa完成  '
echo '///-----------='
echo ''

echo '///-------------'
echo '/// 开始发布ipa包 '
echo '///-------------'

#
#if [ $number == 1 ];then
#
##验证并上传到App Store
## 将-u 后面的XXX替换成自己的AppleID的账号，-p后面的XXX替换成自己的密码
#altoolPath="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
#"$altoolPath" --validate-app -f ${exportIpaPath}/${scheme_name}.ipa -u XXX -p XXX -t ios --output-format xml
#"$altoolPath" --upload-app -f ${exportIpaPath}/${scheme_name}.ipa -u  XXX -p XXX -t ios --output-format xml
#else

#上传到Fir
# 将XXX替换成自己的Fir平台的token

token=${4}

if [ "$token" =  "" ];
then
echo '///-----------'
echo '/// 未输入fir token,跳过上传到fir'
echo '///-----------'
exit 0
else
echo '///-------------'
echo '/// 开始发布到fir '
echo '///-------------'
fir login -T $token
fir publish $exportIpaPath/$scheme_name.ipa -Q -s ${token:0:18}
#fi
open -a "/Applications/Safari.app" http://d.6short.com/${token:0:18}
fi

PGYUSERKEY=${5}
PGYAPIKEY=${6}
PASSWORD=${7}

if [ "$PGYUSERKEY" !=  "" ] && [ "$PGYUSERKEY" !=  "" ];
then
echo '///-------------'
echo '/// 开始发布到蒲公英 '
echo '///-------------'
# 上传到蒲公英
curl -F "file=@${exportIpaPath}/${scheme_name}.ipa" \
-F "uKey=$PGYUSERKEY" \
-F "_api_key=$PGYAPIKEY" \
-F "installType=2" \
-F "password=$PASSWORD" \
https://qiniu-storage.pgyer.com/apiv1/app/upload


else
echo '///-----------'
echo '/// 未输入api key 和 user key,跳过上传到蒲公英'
echo '///-----------'
fi


exit 0



