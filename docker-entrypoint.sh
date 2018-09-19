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

SECRETS_FILE="/run/secrets/${SECRETS}"

if [ -f ${SECRETS_FILE} ]; then
    SERVER_DOMAIN=$(crudini --get ${SECRETS_FILE} general domain)
    SERVER_EMAIL=$(crudini --get ${SECRETS_FILE} general email)
    IS_DEBUG=$(crudini --get ${SECRETS_FILE} general debug)
    GRPC_SERVER_ADDRESS=$(crudini --get ${SECRETS_FILE} grpc_server grpc_server_address)
    GRPC_SERVER_PORT=$(crudini --get ${SECRETS_FILE} grpc_server grpc_server_port)
fi


if [ -z ${SERVER_DOMAIN} ]; then
    error "You should specify your domain."
    exit 1
fi


info "Generate a default configuration"

cat <<EOF > /etc/nginx/conf.d/server.conf

client_max_body_size 20m;

server {
listen 80;
access_log /var/log/nginx/proxy.http.access.log main;
error_log /var/log/nginx/proxy.http.error.log warn;
server_name ${SERVER_DOMAIN};

location / {
root /usr/share/nginx/html;
index index.html index.htm;
}
}
EOF

if [ -n "${GRPC_SERVER_ADDRESS}" ] && [ -n "${GRPC_SERVER_PORT}" ]; then
cat<<EOF >> /etc/nginx/conf.d/server.conf
upstream grpcservers{
server ${GRPC_SERVER_ADDRESS}:${GRPC_SERVER_PORT};
}

server {
listen 50051 http2;
access_log /var/log/nginx/proxy.grpc.access.log main;
error_log /var/log/nginx/proxy.grpc.error.log warn;
server_name ${SERVER_DOMAIN};
location / {
grpc_pass grpc://grpcservers;
}
}
EOF

fi

info "Print default configuration..."

cat /etc/nginx/conf.d/server.conf

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