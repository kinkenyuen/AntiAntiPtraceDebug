#当前项目目录下的TargetApp文件夹，里面放ipa包
ASSETS_PATH="${SRCROOT}/TargetApp"

#临时目录
TEMP_PATH="${SRCROOT}/Temp"

#目标ipa包路径
TARGET_IPA_PATH="${ASSETS_PATH}/*.ipa"

#每次运行前都清空Temp文件夹
rm -rf "${SRCROOT}/Temp"
mkdir -p "${SRCROOT}/Temp"

#-----------------------------------------#
#解压缩ipa
unzip -oqq "${TARGET_IPA_PATH}" -d "${TEMP_PATH}"

#获取解压后的app路径
TEMP_APP_PATH=$(set -- "${TEMP_PATH}/Payload/"*.app;echo "$1")

#获取当前工程编译app的路径
TARGET_APP_PATH="${BUILT_PRODUCTS_DIR}/${TARGET_NAME}.app"

#清空一下工程生成的App包
rm -rf "${TARGET_APP_PATH}"
mkdir -p "${TARGET_APP_PATH}"

#-----------------------------------------#

#将三方应用app拷贝到当前工程编译app的路径
cp -rf "${TEMP_APP_PATH}/" "${TARGET_APP_PATH}"

#删除一些免费开发者账户签名不了的内容
rm -rf "$TARGET_APP_PATH/PlugIns"
rm -rf "$TARGET_APP_PATH/Watch"

#修改三方应用的Info.plist文件
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $PRODUCT_BUNDLE_IDENTIFIER" "$TARGET_APP_PATH/Info.plist"

# 拿到MachO文件的路径
APP_BINARY=`plutil -convert xml1 -o - $TARGET_APP_PATH/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`
#上可执行权限
chmod +x "$TARGET_APP_PATH/$APP_BINARY"

#重签Frameworks
TARGET_FRAMEWORKS_PATH="${TARGET_APP_PATH}/Frameworks"
if [ -d "${TARGET_FRAMEWORKS_PATH}"]; 
	then
for FRAMEWORK in "${TARGET_FRAMEWORKS_PATH}/"*
do
	/usr/bin/codesign --force --sign "$EXPANDED_CODE_SGIN_IDENTITY" "$FRAMEWORK"
done
fi

#注入自己编写的framework
INJECT_FRAMEWORK_PATH="Frameworks/AntiAnti.framework/AntiAnti"

yololib "$TARGET_APP_PATH/$APP_BINARY" "$INJECT_FRAMEWORK_PATH"

