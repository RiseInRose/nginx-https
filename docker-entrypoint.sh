#!/bin/sh

set -e

function info() {
    >&2 echo "[$(date "+%Y-%m-%d %H:%M:%S")][Info]" "$@"
}

function warning() {
    >&2 echo "[$(date "+%Y-%m-%d %H:%M:%S")][Warning]" "$@"
}

function error() {
    >&2 echo "[$(date "+%Y-%m-%d %H:%M:%S")][Error]" "$@"
}

info "NGinx reverse proxy setting"

SECRET_FILE="/run/secrets/${SECRET_NAME}"

if [ -z ${INI_SECTION} ]; then
    INI_SECTION=''
fi

if [ -f ${SECRET_FILE} ]; then
    SERVER_DOMAIN=$(crudini --get ${SECRET_FILE} "${INI_SECTION}" server_domain)
    SERVER_EMAIL=$(crudini --get ${SECRET_FILE} "${INI_SECTION}" server_email)
    IS_DEBUG=$(crudini --get ${SECRET_FILE} "${INI_SECTION}" debug)
fi


if [ -z ${SERVER_DOMAIN} ]; then
    error "You should specify your domain."
    exit 1
fi


info "Generate a default configuration"

cat <<EOF > /etc/nginx/conf.d/default.conf

client_max_body_size 20m;

server {
    listen 80;
    access_log /var/log/nginx/proxy.http.access.log main;
    error_log /var/log/nginx/proxy.http.error.log warn;
    server_name ${SERVER_DOMAIN};

    include /home/conf/nginx/http.loc*.conf;
}

server {
    listen 50051 http2;
    access_log /var/log/nginx/proxy.grpc.access.log main;
    error_log /var/log/nginx/proxy.grpc.error.log warn;

    include /home/conf/nginx/grpc.loc*.conf;
}

include /home/conf/nginx/ups*.conf;
EOF


info "Print default configuration..."

cat /etc/nginx/conf.d/default.conf

if [ -z ${SERVER_EMAIL} ]; then
    info "There is no email for Https certification. Setting Complete."
    info "Start NGinx on Background."
    nginx -g 'daemon off;'
    exit 0
fi

info "Try to get Https certification with an account, ${SERVER_EMAIL}"

info "Start temporarily NGinx on Foreground"

nginx -g 'daemon on;'

sleep 10s


if [ ${IS_DEBUG} = "true" ]; then
    info "Get Https certificate with staging mode -- This certificate should be used only for development!"
    certbot --staging --nginx --redirect --email ${SERVER_EMAIL} --agree-tos --no-eff-email -d ${SERVER_DOMAIN}
else
    info "Get Https certificate..."
    certbot --nginx --redirect --email ${SERVER_EMAIL} --agree-tos --no-eff-email -d ${SERVER_DOMAIN}
fi

if [ $? -ne 0 ]; then
    error "There are some problems when getting a certificate; maybe a rate limit or invalid email."
    exit 1
fi

info "Stop NGinx on Foreground"
nginx -s quit
sleep 10s


info "Generate cronjob for renewing certification."
mkdir -p /var/log/cronjob/
cat <<EOF > /home/renew-cert.sh 
0 8 12 * * certbot renew --nginx
EOF
chmod +x /home/renew-cert.sh
crontab /home/renew-cert.sh

info "Start cron.."
crond -b -l 2 -L /var/log/cron/cronjob.log

info "start NGinx on background..."
nginx -g 'daemon off;'

info "Setting complete!"

exit 0