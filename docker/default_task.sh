#!/bin/sh
set -e

function initPythonEnv() {
  echo "-------------Start install python3 env"
  apk add --update jpeg-dev gcc g++ python3 python3-dev py3-pip py3-cryptography py3-numpy py-pillow mysql-dev libffi-dev openssl-dev zlib-dev freetype-dev lcms2-dev openjpeg-dev tiff-dev tk-dev tcl-dev
  cd /scripts/docker/bot
  python3 --version
  pip3 install --upgrade pip setuptools wheel
  python3 --version
  pip3 install -r requirements.txt
  python3 setup.py install
}

echo "step 1) Start to set up python3 env and TG bot ##################################"
if [ "$1" == "True" ]; then
  initPythonEnv
  if [ -z "$DISABLE_SPNODE" ]; then
    echo "增加命令组合spnode ，使用该命令spnode jd_xxxx.js 执行js脚本会读取cookies.conf里面的jd cokie账号来执行脚本"
    (
      cat <<EOF
#!/bin/sh
set -e
first=\$1
cmd=\$*
echo \${cmd/\$1/}
if [ \$1 == "conc" ]; then
    for job in \$(cat \$COOKIES_LIST | grep -v "#" | paste -s -d ' '); do
        { export JD_COOKIE=\$job && node \${cmd/\$1/}
        }&
    done
elif [ -n "\$(echo \$first | sed -n "/^[0-9]\+\$/p")" ]; then
    echo "\$(echo \$first | sed -n "/^[0-9]\+\$/p")"
    { export JD_COOKIE=\$(sed -n "\${first}p" \$COOKIES_LIST) && node \${cmd/\$1/}
    }&
elif [ -n "\$(cat \$COOKIES_LIST  | grep "pt_pin=\$first")" ];then
    echo "\$(cat \$COOKIES_LIST  | grep "pt_pin=\$first")"
    { export JD_COOKIE=\$(cat \$COOKIES_LIST | grep "pt_pin=\$first") && node \${cmd/\$1/}
    }&
else
    { export JD_COOKIE=\$(cat \$COOKIES_LIST | grep -v "#" | paste -s -d '&') && node \$*
    }&
fi
EOF
    ) >/usr/local/bin/spnode
    chmod +x /usr/local/bin/spnode
  fi

  echo "spnode需要使用的到，cookie写入文件，该文件同时也为jd_bot扫码获自动取cookies服务"
  if [ -z "$JD_COOKIE" ]; then
    if [ ! -f "$COOKIES_LIST" ]; then
      echo "" >"$COOKIES_LIST"
      echo "未配置JD_COOKIE环境变量，$COOKIES_LIST文件已生成,请将cookies写入$COOKIES_LIST文件，格式每个Cookie一行"
    fi
  else
    if [ -f "$COOKIES_LIST" ]; then
      echo "cookies.conf文件已经存在跳过,如果需要更新cookie请修改$COOKIES_LIST文件内容"
    else
      echo "环境变量 cookies写入$COOKIES_LIST文件,如果需要更新cookie请修改cookies.conf文件内容"
      echo $JD_COOKIE | sed "s/[ &]/\\n/g" | sed "/^$/d" >$COOKIES_LIST
    fi
  fi

  CODE_GEN_CONF=/scripts/logs/code_gen_conf.list
  echo "生成互助消息需要使用的到的 logs/code_gen_conf.list 文件，后续需要自己根据说明维护更新删除..."
  if [ ! -f "$CODE_GEN_CONF" ]; then
    touch CODE_GEN_CONF
  else
    echo "logs/code_gen_conf.list 文件已经存在跳过初始化操作"
  fi
  curl -sX POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" -d "chat_id=$TG_USER_ID&text=Congratulation🎉,tg bot set up succcessfully" >> /dev/null
fi

echo "step 2) Start to set up cronjob  ##################################"
defaultListFile="/scripts/docker/$DEFAULT_LIST_FILE"
mergedListFile="/scripts/docker/merged_list_file.sh"
cat $defaultListFile >$mergedListFile
echo "Using default cronlist $DEFAULT_LIST_FILE ..."

echo "step 3) Append docker_entrypoint.sh into crond ##################################"
sed -ie '/'docker_entrypoint.sh'/d' ${mergedListFile}
if [ $(date +%-H) -lt 12 ]; then
  random_h=$(($RANDOM % 12 + 12))
else
  random_h=$(($RANDOM % 12))
fi
random_m=$(($RANDOM % 60))
echo -e "${random_m} ${random_h} * * * docker_entrypoint.sh >> /scripts/logs/default_task.log 2>&1" | tee -a $mergedListFile

echo "step 4) Replace running time ##################################"
sed -i "/\( ts\| |ts\|| ts\)/!s/>>/\|ts >>/g" $mergedListFile

echo "step 5) Reload the latest cronjob list ##################################"
if [[ -f /usr/bin/jd_bot && -z "$DISABLE_SPNODE" ]]; then
  sed -i "s/ node / spnode /g" $mergedListFile
fi
crontab $mergedListFile

echo "step 6) Copy the docker_entrypoint.sh into container bin dir  ##################################"
cat /scripts/docker/docker_entrypoint.sh > /usr/local/bin/docker_entrypoint.sh

echo "step 7) : install typescript"
npm install -g typescript