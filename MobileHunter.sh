#!/bin/bash

A='\033[1;34m'
B='\033[1;32m'
NC='\033[0m'

if [ "$#" -ne 1 ]; then
  echo -e "You must run the tool like that: ${A}$0 AppName.apk${NC}"
  exit 0
fi

APP=$1
rm -r unzip_folder jadx_folder apktool_folder > /dev/null 2>&1

shapeA () {
  echo ""
  echo "######################################################################"
  echo ""
  sleep 2
}

shapeB () {
  echo ""
  echo "#################################"
  echo ""
  sleep 2
}

# Unzipping archive
shapeA
echo -e "${A}Performing Reverse Engineering...${NC}"
shapeA
echo -e "${B}Unzipping the Application (saved as unzip_folder)...${NC}"
unzip $APP -d unzip_folder > /dev/null 2>&1

# Jadx (generate java code)
echo -e "${B}Decompiling the Application Using Jadx Tool (saved as jadx_folder)...${NC}"
/usr/share/jadx/bin/jadx $APP -d jadx_folder > /dev/null 2>&1

# To read AndroidManifest.xml and generate smali files
echo -e "${B}Extracting the Manifest.xml File Using APKTool (saved as apktool_folder)...${NC}"
apktool d $APP -o apktool_folder > /dev/null 2>&1

echo -e "${B}Extracting the Signing Certificate...${NC}"
jarsigner -verify -verbose -certs $APP | grep "Signed\|algorithm:"
apksigner verify --verbose $APP | grep "Verified"

shapeA
echo -e "${A}Parsing AndroidManifest.xml...${NC}"
shapeA

echo -e "${B}Parsing Debug & Backup Flags...${NC}"
cat apktool_folder/AndroidManifest.xml | grep -i "debuggable\|allowbackup" | sed -E 's/^[ ]+//g' | grep --color=auto -i "debuggable\|allowbackup"

echo -e "${B}Parsing Permissions...${NC}"
cat apktool_folder/AndroidManifest.xml | grep -i "uses-permission" | sed -E 's/^[ ]+//g' | grep --color=auto -i "uses-permission"

echo -e "${B}Parsing Exported Flag...${NC}"
cat apktool_folder/AndroidManifest.xml | grep -i 'exported="true"' | sed -E 's/^[ ]+//g' | grep --color=auto -i 'exported="true"'

echo -e "${B}Parsing Intent-Filters...${NC}"
xmllint apktool_folder/AndroidManifest.xml --xpath '//activity[intent-filter]' 2>/dev/null
xmllint apktool_folder/AndroidManifest.xml --xpath '//receiver[intent-filter]' 2>/dev/null

# echo -e "${B}To exploit exported activities: ${NC}"
# echo -e "adb shell am start -a action_name"
# echo -e "adb shell am start -n package_name/.activity_name"
# echo -e "${B}To exploit exported content providers: ${NC}"
# echo -e "adb shell content query --uri content://full_path"
# echo -e "${B}To exploit exported broadcast recievers: ${NC}"
# echo -e "adb shell am broadcast -n package_name/.reciever_name -a action_name --es string1 4444 --es string2 12345 --ez boolean true"

shapeA
echo -e "${A}Performing Security Checking...${NC}"
shapeA

shapeB
echo -e "${B}Searching for Content Providers and URLS...${NC}"
shapeB
strings unzip_folder/classes.dex | grep -i "content://[a-zA-Z0-9\.\/\_\-]\+\|http[s]*://[a-zA-Z0-9\.\/\_\-]\+" | sed 's/^[ ]*//g' | grep --color=auto -i "content://[a-zA-Z0-9\.\/\_\-]\+\|http[s]*://[a-zA-Z0-9\.\/\_\-]\+"

PackageName=$(xmllint --xpath '//manifest/@package' apktool_folder/AndroidManifest.xml | cut -d '"' -f 2 | sed 's/\./\//g')
echo "Package Name:" $PackageName

# Search for Logs
shapeB
echo -e "${B}Searching for Logs...${NC}"
shapeB
grep --color=auto -r "Log\." jadx_folder 2>/dev/null

# Search for Storage
shapeB
echo -e "${B}Searching for Storage...${NC}"
shapeB
grep --color=auto -r "getSharedPreferences\|getDefaultSharedPreferences\|getExternal\|FileOutPutStream" jadx_folder 2>/dev/null
grep --color=auto -r "MODE_WOBLD_BEADABLE\|MODE_WOBLD_WBITABLE" jadx_folder 2>/dev/null

shapeB
echo -e "${B}Searching for Javascript Enabled...${NC}"
shapeB
grep --color=auto -r "setJavaScriptEnabled" jadx_folder 2>/dev/null

# Search for SQL Injection
shapeB
echo -e "${B}Searching for Databases...${NC}"
shapeB
grep --color=auto -r "execSQL\|rawQuery" jadx_folder 2>/dev/null

# Search for Temp Files
shapeB
echo -e "${B}Searching for Temp Files...${NC}"
shapeB
grep --color=auto -r "TempFile" jadx_folder 2>/dev/null

# Search for URLs
shapeB
echo -e "${B}Searching for URLs...${NC}"
shapeB
grep --color=auto -r "content://[a-zA-Z0-9\.\/\_\-]\+\|http[s]*://[a-zA-Z0-9\.\/\_\-]\+" jadx_folder 2>/dev/null

# Search binary files for insecure functions
shapeB
echo -e "${B}Searching for Insecure Functions...${NC}"
shapeB
grep --color=auto -ir "strcat\|strcpy\|strncat\|strlcat\|strncpy\|strlcpy\|sprintf\|snprintf" jadx_folder 2>/dev/null

shapeA
echo -e "${A}Searching for Possible Credentials...${NC}"
shapeA
grep --color=auto -ri "password\|user\|key\|secret" jadx_folder 2>/dev/null

# Dynamic Analysis
# adb shell logcat -d | grep $(adb shell ps -A | grep jakhar.aseem.diva | awk '{print $2}')
# adb shell "su -c 'ls -l /data/data/jakhar.aseem.diva/*'"
# adb shell "su -c 'find / -user root -type f -exec ls -l {} \; | grep 2021-03-25 2>/dev/null' 2>/dev/null" | grep -v "/sys/\|/proc/\|/dev/"
