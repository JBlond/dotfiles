#!/bin/bash
# repo  https://github.com/certbot/certbot
sudo /opt/apache2/bin/httpd -k stop
sudo certbot renew --agree-tos --no-self-upgrade --no-bootstrap
sudo /opt/apache2/bin/httpd -k start
