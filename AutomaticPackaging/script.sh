#!/bin/sh

#项目本地路径
project_path=${1}
#打包类型
number=${2}
#teamID
teamID=${3}
#fir token
token=${4}
#蒲公英的user key
PGYUSERKEY=${5}
#蒲公英的api key
PGYAPIKEY=${6}
#蒲公英的安装密码
PASSWORD=${7}
#打包模式
model_type=${8}
#是否选中App Store
is_seleted_app_store=${9}
#是否选中fir
is_seleted_fir=${10}
#是否选中蒲公英
is_seleted_pgy=${11}
#操作类型
typeNum=${12}
 #ipaPath
ipaPath=${13}
#mobileprovision文件
mobileprovision_file=${14}
appid=${15}
appid_pwd=${16}
 if [ ${typeNum} == "0" ];then
 
    if [ ${model_type} == "0" ];then
        development_mode=Release
    else
        development_mode=Debug
    fi

    #项目沙盒路径
    project_sandBox_path=$(cd `dirname $0`; pwd)
    
    mobileprovision_teamname=`/usr/libexec/PlistBuddy -c "Print TeamName" /dev/stdin <<< $(security cms -D -i $mobileprovision_file)`
    echo $mobileprovision_teamname
    CODE_SIGN_IDENTITY="iPhone Distribution: $mobileprovision_teamname"
    echo "$CODE_SIGN_IDENTITY"
    PROVISIONING_PROFILE_SPECIFIER=`/usr/libexec/PlistBuddy -c "Print AppIDName" /dev/stdin <<< $(security cms -D -i $mobileprovision_file)`
    echo "AppIDName:"$PROVISIONING_PROFILE_SPECIFIER
    UUID=`/usr/libexec/PlistBuddy -c "Print UUID" /dev/stdin <<< $(security cms -D -i $mobileprovision_file)`
    echo "UUID:"$UUID
    Name=`/usr/libexec/PlistBuddy -c "Print Name" /dev/stdin <<< $(security cms -D -i $mobileprovision_file)`
    echo "Name:"$Name
    TeamIdentifier=`/usr/libexec/PlistBuddy -c "Print TeamIdentifier:0" /dev/stdin <<< $(security cms -D -i $mobileprovision_file)`
    echo "TeamIdentifier:"$TeamIdentifier
    ApplicationIdentifierPrefix=`/usr/libexec/PlistBuddy -c "Print ApplicationIdentifierPrefix:0" /dev/stdin <<< $(security cms -D -i $mobileprovision_file)`
    echo "ApplicationIdentifierPrefix:"${ApplicationIdentifierPrefix}

    PROVISIONING_PROFILE_SPECIFIER=`/usr/libexec/PlistBuddy -c "Print Entitlements:application-identifier" /dev/stdin <<< $(security cms -D -i $mobileprovision_file)`
    echo "AppID:"${PROVISIONING_PROFILE_SPECIFIER}
    BUNDLE_ID=${PROVISIONING_PROFILE_SPECIFIER#*${ApplicationIdentifierPrefix}.}
    echo $BUNDLE_ID
    
   
    
    #plist文件所在沙盒路径
    exportAdHocPlistPath=${project_sandBox_path}/exportAdHoc.plist
    exportAppstorePlistPath=${project_sandBox_path}/exportAppstore.plist
    exportEnterprisePlistPath=${project_sandBox_path}/exportEnterprise.plist
    #install.sh文件所在沙盒路径
    installShPath=${project_sandBox_path}/install.sh

    echo '******\n检索是否存在工程项目\n******'
    files=$(ls $project_path)
    echo $files
    for filename in $files
        do
            if [ ${filename##*.} == "xcworkspace" ];then
                #工程名
                project_name=${filename%.*}
                #scheme名
                scheme_name=${filename%.*}
                project_type=1
            else
                if [ ${filename##*.} == "xcodeproj" ];then
                    #工程名
                    project_name=${filename%.*}
                    #scheme名
                    scheme_name=${filename%.*}
                    project_type=2
                fi
            fi
        done


    if [ "$project_name" =  "" ];then
        echo '******\n未检索到xcworkspace项目，进程终止，请使用CocoaPods生成xcworkspace项目\n******'
        exit 0
    else
        echo '******\n已检索到工程项目\n******'
    fi


    if [ ${number} == "1" ];then
        echo '******\n开始执行内测版本打包程序\n******'
    elif [ ${number} == "2" ];then
        echo '******\n开始执行分发版本打包程序\n******'
    else
        if [ "$mobileprovision_file" = "" ];then
            echo '******\nApp Store打包需要选择描述文件\n******'
            exit 0
        fi
        echo '******\n开始执行App Store打包程序\n******'
        /usr/libexec/PlistBuddy -c "Delete provisioningProfiles" $exportAppstorePlistPath
        /usr/libexec/PlistBuddy -c "Add provisioningProfiles dict" $exportAppstorePlistPath
        /usr/libexec/PlistBuddy -c "Add provisioningProfiles:$BUNDLE_ID string $Name" $exportAppstorePlistPath
        /usr/libexec/PlistBuddy -c "Set teamID $TeamIdentifier" $exportAppstorePlistPath
        
        
    fi
# exit
    
    #cp -r ${exportEnterprisePlistPath} ${project_path}


    # cd到APP项目路径
    cd ${project_path}

    if [ ! -d ./IPADir ];
    then
    mkdir -p IPADir;
    fi

    #build文件夹路径
    build_path=${project_path}/build
    #plist文件所在路径
    #exportOptionsPlistPath=${project_path}/exportAdHoc.plist
    #导出.ipa文件所在路径
    exportIpaPath=${project_path}/IPADir/${development_mode}

    #检测打包类型
    if [ ${number} == "1" ];then
    echo '******\n检测打包类型为内测'
    exportOptionsPlistPath=${project_sandBox_path}/exportAdHoc.plist
    elif [ ${number} == "2" ];then
    echo '******\n检测打包类型为分发'
    exportOptionsPlistPath=${project_sandBox_path}/exportEnterprise.plist
    else
    echo '******\n检测打包类型为App Store'
    exportOptionsPlistPath=${project_sandBox_path}/exportAppstore.plist
    fi
    rm -rf ${project_path}/build
    echo '******\n正在清理工程'
    xcodebuild \
    clean -configuration ${development_mode} -quiet  || exit

    echo '******\n清理完成'

    echo '******\n正在编译工程:'${development_mode}
    if [ $project_type == 1 ]; then
       echo "编译方式一"
       xcodebuild \
       archive -workspace ${project_path}/${project_name}.xcworkspace \
       -scheme ${scheme_name} \
       -configuration ${development_mode} \
       -archivePath ${build_path}/${project_name}.xcarchive  -quiet  || exit
    else
       echo "编译方式二"
       xcodebuild \
       archive -project ${project_path}/${project_name}.xcodeproj \
       -scheme ${scheme_name} \
       -configuration ${development_mode} \
       -archivePath ${build_path}/${project_name}.xcarchive  -quiet  || exit
    fi
    echo '******\n编译完成，开始ipa打包'
    xcodebuild -exportArchive -archivePath ${build_path}/${project_name}.xcarchive \
    -configuration ${development_mode} \
    -exportPath ${exportIpaPath} \
    -exportOptionsPlist ${exportOptionsPlistPath} \
    -quiet || exit

    if [ -e $exportIpaPath/$scheme_name.ipa ]; then
    echo '******\n ipa包已导出'
    #open $exportIpaPath
    else
    echo '******\nipa包导出失败 '
    fi
    echo '******\n打包ipa完成：'$exportIpaPath/$scheme_name.ipa
    open $exportIpaPath


    if [ "$is_seleted_app_store" =  "1" ];then
        #验证并上传到App Store
            # 将-u 后面的XXX替换成自己的AppleID的账号，-p后面的XXX替换成自己的密码
       if [ "$appid" !=  "" ] && [ "$appid_pwd" !=  "" ];then
            echo '******\n开始上传到App Store '
        altoolPath="/Applications/Xcode.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/Versions/A/Frameworks/AppStoreService.framework/Versions/A/Support/altool"
            "$altoolPath" --validate-app -f ${exportIpaPath}/${scheme_name}.ipa -u $appid -p $appid_pwd -t ios --output-format xml
            "$altoolPath" --upload-app -f ${exportIpaPath}/${scheme_name}.ipa -u  $appid -p $appid_pwd -t ios --output-format xml
        else
            echo '上传到App Store账号密码必填'
        fi
    fi

    #上传到Fir
    if [ "$is_seleted_fir" =  "1" ];then
    #判断是否安装 fir
        if [ `command -v fir` ];then
            #判断token是否为空
            if [ "$token" =  "" ];then
                echo '******\n未输入fir token,跳过上传到fir'
            else
                echo '******\n开始发布到fir '
                fir login -T $token
                fir publish $exportIpaPath/$scheme_name.ipa -Q
            fi
        else
            echo 'fir 未安装,请使用 gem install fir-cli 指令安装'
        fi
    fi

    # 上传到蒲公英
    if [ "$is_seleted_pgy" =  "1" ];then
        #API KEY 、USER KEY
        if [ "$PGYUSERKEY" !=  "" ] && [ "$PGYUSERKEY" !=  "" ];then
            echo '******\n开始发布到蒲公英 '
            curl -F "file=@${exportIpaPath}/${scheme_name}.ipa" \
            -F "uKey=$PGYUSERKEY" \
            -F "_api_key=$PGYAPIKEY" \
            -F "installType=2" \
            -F "password=$PASSWORD" \
            https://qiniu-storage.pgyer.com/apiv1/app/upload
        else
            echo '******\n未输入api key 和 user key,跳过上传到蒲公英'
        fi
    fi
elif [ ${typeNum} == "1" ];then

    if [ `command -v fir` ];then
        #判断token是否为空
        if [ "$token" =  "" ];then
            echo '******\n未输入fir token,跳过上传到fir'
        else
            echo '******\n开始发布到fir '
            fir login -T $token
            fir publish "$ipaPath" -Q
#            open -a "/Applications/Safari.app" http://d.6short.com/${token:0:18}
        fi
    else
        echo 'fir 未安装,请使用 gem install fir-cli 指令安装'
    fi
elif [ ${typeNum} == "2" ];then

    #API KEY 、USER KEY
    if [ "$PGYUSERKEY" !=  "" ] && [ "$PGYUSERKEY" !=  "" ];then
        echo '******\n开始发布到蒲公英 '
        curl -F "file=@$ipaPath" \
        -F "uKey=$PGYUSERKEY" \
        -F "_api_key=$PGYAPIKEY" \
        -F "installType=2" \
        -F "password=$PASSWORD" \
        https://qiniu-storage.pgyer.com/apiv1/app/upload
    else
        echo '******\n未输入api key 和 user key,跳过上传到蒲公英'
    fi
elif [ ${typeNum} == "3" ];then

        #验证并上传到App Store
     if [ "$appid" !=  "" ] && [ "$appid_pwd" !=  "" ];then
          echo '******\n开始上传到App Store '
      altoolPath="/Applications/Xcode.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/Versions/A/Frameworks/AppStoreService.framework/Versions/A/Support/altool"
          "$altoolPath" --validate-app -f "$ipaPath" -u $appid -p $appid_pwd -t ios --output-format xml
          "$altoolPath" --upload-app -f "$ipaPath" -u  $appid -p $appid_pwd -t ios --output-format xml
      else
          echo '上传到App Store账号密码必填'
      fi

fi


exit 0



