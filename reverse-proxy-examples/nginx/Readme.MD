# NGINX Config example

Your config could look like this:

```
server {
    listen 80 default_server;
    listen [::]:80 ipv6only=on default_server;
    server_name pretalx.mydomain.com;
    return 301 https://pretalx.mydomain.com$request_uri;
}
server {
    listen 443 default_server;
    listen [::]:443 ipv6only=on default_server;
    server_name pretalx.mydomain.com;

    ssl on;
    ssl_certificate /path/to/cert.chain.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8346/;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header Host $http_host;
    }

    location /media/ {
      alias /path/to/pretalx/data/media/;
      add_header Content-Disposition 'attachment; filename="$1"';
      expires 7d;
      access_log off;
    }

}
```
