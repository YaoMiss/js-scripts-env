10 8,13,20 * * * node /scripts/jd_speed_coin.js >> /scripts/logs/jd_speed_coin.log 2>&1
2 7-22/1 * * * node /scripts/jd_plantBean.js >> /scripts/logs/jd_plantBean.log 2>&1
15 6-18/4 * * * node /scripts/jd_pet.js >> /scripts/logs/jd_pet.log 2>&1
15 6-18/4 * * * node /scripts/jd_fruit.js >> /scripts/logs/jd_fruit.log 2>&1
2 8,13,20 * * * node /scripts/jd_bean_box.js | ts >> /scripts/logs/jd_bean_box.log 2>&1

44 0 * * * docker_entrypoint.sh >> /scripts/logs/default_task.log 2>&1