FROM node:lts-alpine3.12

LABEL AUTHOR="none" \
      VERSION=1.0

ENV DEFAULT_LIST_FILE=crontab_list.sh \
    CUSTOM_LIST_MERGE_TYPE=append \
    COOKIES_LIST=/scripts/logs/cookies.list \
    REPO_URL=https://gitlab.com/biyongyao/jd-scripts.git \
    JD_SCRIPT_REPO_URL=https://github.com/Toulu-debug/enen.git \
    REPO_BRANCH=master \
    NPM_RESOURCE=https://registry.npm.taobao.org

RUN set -ex \
    && apk update \
    && apk upgrade \
    && apk add --no-cache bash tzdata git moreutils curl jq openssh-client gcc \
    && rm -rf /var/cache/apk/* \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && git clone $JD_SCRIPT_REPO_URL /scripts \
    && git clone $REPO_URL /scripts_env \
    && cp -r /scripts_env/docker /scripts/ \
    && cd /scripts && mkdir logs \
    && npm config set registry $NPM_RESOURCE && npm install \
    && cp /scripts/docker/docker_entrypoint.sh /usr/local/bin && chmod +x /usr/local/bin/docker_entrypoint.sh

WORKDIR /scripts

ENTRYPOINT ["docker_entrypoint.sh"]

CMD [ "crond" ]