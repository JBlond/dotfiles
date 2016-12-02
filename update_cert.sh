#!/bin/bash
sudo /opt/apache2/bin/httpd -k stop
sudo /root/certbot/letsencrypt-auto renew
sudo /opt/apache2/bin/httpd -k start
