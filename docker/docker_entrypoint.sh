#!/bin/sh
set -e

if [ -n "$1" ]; then
  run_cmd=$1
fi

(
if [ -f "/scripts/logs/pull.lock" ]; then
  echo "git was locked,exit..."
else
  echo ">>>>>>>>>>>>>Entrypoint script ---- initialize..."
  cd /scripts
  git remote set-url origin "$JD_SCRIPT_REPO_URL"
  echo ">>>>>>>>>>>>>Entrypoint script ---- clear the code..."
  git reset --hard
  git clean -f
  echo ">>>>>>>>>>>>>Entrypoint script ---- git pull 拉取最新代码..."
  git -C /scripts pull --rebase
  echo ">>>>>>>>>>>>>Entrypoint script ---- npm install 安装最新依赖"
  npm install --prefix /scripts
fi
) || exit 0


if [[ -n "$run_cmd" && -n "$TG_BOT_TOKEN" && -n "$TG_USER_ID" && -z "$DISABLE_BOT_COMMAND" && -z "$TG_API_HOST" ]]; then
  ENABLE_BOT_COMMAND=True
else
  ENABLE_BOT_COMMAND=False
fi

echo "--------------------------------------------------Initialize Default Task Start----------------------------------------------"
sh /scripts/docker/default_task.sh "$ENABLE_BOT_COMMAND" "$run_cmd"
echo "--------------------------------------------------Initialize Default Task Finish---------------------------------------------------"

if [ -n "$run_cmd" ]; then
  if [[ "$ENABLE_BOT_COMMAND" == "True" && -f /usr/bin/jd_bot ]]; then
    echo ">>>>>>>>>>Entrypoint starts crond process..."
    crond
    echo ">>>>>>>>>>Entrypoint starts JD BOT..."
    jd_bot
  else
    echo ">>>>>>>>>>Entrypoint starts crond process..."
    crond -f
  fi

else
  echo "Default Task was done"
fi