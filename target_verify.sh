#!/bin/sh
# 将此文件里面的命令放到 Build Phases -> Run Script 脚本中
echo "start verify target..."
pwd
declare -a cmd_list=("ruby ./script/target_verify/target_verify.rb ./xxx.xcodeproj <#target name first#> <#target name last#>"
"ruby ./script/target_verify/asset_verify.rb ./xxxx/xxxx.xcassets ./xxxx/xxx.xcassets")
for cmd in "${cmd_list[@]}"
do
    eval "$cmd"
    if [ $? -ne 0 ]
    then
    echo "FAILED"
    exit 1
    fi
done
echo "finished target verify and no issue found"
