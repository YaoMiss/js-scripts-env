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

echo "################################## step 1) Start to set up python3 and TG bot ##################################"
if [ "$1" == "True" ]; then
  initPythonEnv
  if [ -z "$DISABLE_SPNODE" ]; then
    echo ">>>>>>>>>>>>>>>>>> spnode jd_xxxx.js will read the file cookies.conf"
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

  echo ">>>>>>>>>>>>>>>>>> start to create the cookies.conf"
  if [ -z "$JD_COOKIE" ]; then
    if [ ! -f "$COOKIES_LIST" ]; then
      echo "" >"$COOKIES_LIST"
    fi
  else
    if [ -f "$COOKIES_LIST" ]; then
      echo ">>>>>>>>>>>>>>>>>> cookies.conf is existing"
    else
      echo $JD_COOKIE | sed "s/[ &]/\\n/g" | sed "/^$/d" >$COOKIES_LIST
    fi
  fi

  CODE_GEN_CONF=/scripts/logs/code_gen_conf.list
  if [ ! -f "$CODE_GEN_CONF" ]; then
    touch CODE_GEN_CONF
  else
    echo "logs/code_gen_conf.list is existing"
  fi
  curl -sX POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" -d "chat_id=$TG_USER_ID&text=Congratulation🎉,tg bot setup succcessfully" >> /dev/null
fi


echo "################################## step 2) Start to set up crond  ##################################"
mergedListFile="/scripts/docker/$DEFAULT_LIST_FILE"
sed -ie '/'docker_entrypoint.sh'/d' ${mergedListFile}
if [ $(date +%-H) -lt 12 ]; then
  random_h=$(($RANDOM % 12 + 12))
else
  random_h=$(($RANDOM % 12))
fi
random_m=$(($RANDOM % 60))

echo -e "${random_m} ${random_h} * * * docker_entrypoint.sh >> /scripts/logs/default_task.log 2>&1" | tee -a $mergedListFile
sed -i "/\( ts\| |ts\|| ts\)/!s/>>/\|ts >>/g" $mergedListFile
if [[ -f /usr/bin/jd_bot && -z "$DISABLE_SPNODE" ]]; then
  sed -i "s/ node / spnode /g" $mergedListFile
fi
crontab $mergedListFile

echo "################################## step 3) Copy the docker_entrypoint.sh into container bin dir  ##################################"
cat /scripts/docker/docker_entrypoint.sh > /usr/local/bin/docker_entrypoint.sh

echo "################################## step 4) : install typescript"
npm install -g typescript
npm install -g ts-node