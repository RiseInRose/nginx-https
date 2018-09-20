# woohyeochoi/nginx-https

This image automatically built NGinx reverse proxy with Https.
It also renews https certificates every month (but, fully tested yet)

## How to use

```bash
docker run -d -p 80:80 -p 443:443 \
           -e IS_DEBUG=true \
           -e SERVER_DOMAIN=*your-server-domain.com* \
           -e SERVER_EMAIL=*your-email@com* \
           woohyeokchoi/nginx-https
```

* You should open ports, 80 (Http) and 443 (Https).

## Environment variables

* (require) **SERVER_DOMAIN**: your server domain
* (require) **SERVER_EMAIL**: your email
* **IS_DEBUG**: if you set "true", Certbot will get https certificats with staging mode. One domain is only allowed to get new Https certificates five times for one day, so it should be set "true" when you try to develop your servers.
* **SECRETS**: If you want to use **Docker Secrets**, you should specify secret name here. The secret file should be a INI format like below:

```bash
[general]
debug = true
domain = your-domain
email = your-email
```