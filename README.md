# woohyeochoi/nginx-https

This Docker image is to automatically build NGinx reverse proxy with Https certificate. Also, it may renew Https certificates every month.

It is based on nginx:alpine Docker image ([link](https://hub.docker.com/_/nginx/)) and Certbot NGinx plugin ([link](https://github.com/certbot/certbot))

## How to use

```bash
docker run -d -p 80:80 -p 443:443 -p 50051:50051 \
           -e IS_DEBUG=true \
           -e SERVER_DOMAIN=your-server-domain.com \
           -e SERVER_EMAIL=your-email@com \
           woohyeokchoi/nginx-https
```

## Cautions

You should open two ports, 80 (Http) and 443 (Https) for certification. If you use gRPC, you should also open 50051.

## Environment variables

* (required) **SERVER_DOMAIN**: Server domain, which not includes scheme (e.g., http, https)
* (required) **SERVER_EMAIL**: Your email address
* **IS_DEBUG**: if you set "true", Certbot will get https certificats with staging mode. One domain is only allowed to get new Https certificates five times for one day, so it should be set "true" when you try to develop your servers.
  
### With Docker Secrets

If you want to use the Docker secret instead of setting environment variables, your secret file should be a format of INI, as below:

```bash
[${INI_SECTION}]
debug = true
server_domain = your-domain
server_email = your-email
```

For the Docker secret, you should set following variables:

* (required) **SECRET_NAME**: Docker secret name. Your secrets are stored in **/run/secrets/${SECRET_NAME}**
* (optional) **INI_SECTION**: The section name where your setting is specified. It can be useful when you specify multiple settings in a single INI file. If not set, it will use global settings.

## Own NGinx Configuration

If you want to use your own NGinx configuration, try to do followings:

```bash
docker run -d -p 80:80 -p 443:443 \
           -e IS_DEBUG=true \
           -e SERVER_DOMAIN=your-server-domain.com \
           -e SERVER_EMAIL=your-email@com \
           -v *YOUR_OWN_CONFIGURATION_FOLDER*:/home/conf/nginx
           woohyeokchoi/nginx-https
```

Currently, this image supports three types of additional NGinx configuration:

* Proxy location for Http redirection

To use it, your configuration file should be named http.loc*.conf (e.g., http.loc.my-conf.conf). In this configuration file, you should set **location** block in NGinx:

```bash
location / {
    proxy_pass http://my.proxy.pass
}
```

* Proxy location for Grpc redirection.

To use it, your configuration file should be named grpc.loc*.conf (e.g., grpc.loc.my-conf.conf). In this configuration file, you should set **location** block in NGinx:

```
location / {
    grpc_pass grpc://my.proxy.pass
}
```

* Upstream

To use it, your configuration file should be named ups*.conf (e.g., upstream-my.conf). In this configuration file, you should set **upstream** block in NGinx:

upstream *my-server-name* {
    server *my-server-address*
}

