#!/bin/bash
# repo  https://github.com/certbot/certbot
sudo /opt/apache2/bin/httpd -k stop
sudo certbot renew --agree-tos
sudo /opt/apache2/bin/httpd -k start
