#!/bin/bash
sudo /opt/apache2/bin/httpd -k stop
sudo /root/certbot/letsencrypt-auto renew --agree-tos --no-self-upgrade --no-bootstrap
sudo /opt/apache2/bin/httpd -k start
