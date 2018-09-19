# https-nginx

This image automatically built NGinx reverse proxy with Https.
It also renews https certificates every month (but, fully tested yet)

## Example
```
docker run -d -p 80:80 -p 443:443 \
           -e IS_DEBUG=true \
           -e SERVER_DOMAIN=*your-server-domain.com* \
           -e SERVER_EMAIL=*your-email@com* \
           woohyeokchoi/https-nginx
```

## Environment variables
* (require) **SERVER_DOMAIN**: your server domain
* (require) **SERVER_EMAIL**: your email
* **IS_DEBUG**: if you set "true", Certbot will get https certificats with staging mode. One domain is only allowed to get new Https certificates five times for one day, so it should be set "true" when you try to develop your servers.

It also support **Docker secrets** (in docker swarm), which are usually stored in /run/secrets/{SECRET_NAME}.
If you want to use docker secret, your secret file should be a INI format like below:

```
[general]
debug = true
domain = your-domain
email = your-email
```