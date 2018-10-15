FROM nginx:alpine
LABEL MAINTAINER="Woohyeok Choi <woohyeok.choi@kaist.ac.kr>"

RUN apk update \
    && apk add --no-cache certbot py2-pip 

RUN pip2 install --upgrade pip \
    && pip2 install --no-cache-dir certbot-nginx crudini

RUN mkdir -p /etc/nginx/conf.d.disabled \
    && mv /etc/nginx/conf.d/* /etc/nginx/conf.d.disabled/ \
    && mkdir -p /scripts \
    && mkdir -p /home/conf/nginx/

RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

COPY ./docker-entrypoint.sh /scripts/

VOLUME [ "/var/log/letsencrypt", "/var/log/nginx", "/etc/letsencrypt/live" ]

EXPOSE 80 443 50051

CMD ["/bin/sh", "/scripts/docker-entrypoint.sh"]