#!/usr/bin/env bash

# PyStead: Updated parameter indices after PHP removal
# Old: $1=map, $2=to, $3=port, $4=ssl, $5=php, $6=params, $7=xhgui, $8=exec, $9=headers, $10=rewrites, $11=prod
# New: $1=map, $2=to, $3=port, $4=ssl, $5=params, $6=exec, $7=headers, $8=rewrites, $9=prod

declare -A params=$5       # Create an associative array (was $6)
declare -A headers=${7}    # Create an associative array (was $9)
declare -A rewrites=${8}   # Create an associative array (was $10)
paramsTXT=""
if [ -n "$5" ]; then
   for element in "${!params[@]}"
   do
      paramsTXT="${paramsTXT}
      fastcgi_param ${element} ${params[$element]};"
   done
fi
headersTXT=""
if [ -n "${7}" ]; then
   for element in "${!headers[@]}"
   do
      headersTXT="${headersTXT}
      add_header ${element} ${headers[$element]};"
   done
fi
rewritesTXT=""
if [ -n "${8}" ]; then
   for element in "${!rewrites[@]}"
   do
      rewritesTXT="${rewritesTXT}
      location ~ ${element} { if (!-f \$request_filename) { return 301 ${rewrites[$element]}; } }"
   done
filename) { return 301 ${rewrites[$element]}; } }"
   done
fi

block="server {
    listen ${3:-80};
    listen ${4:-443} ssl http2;
    server_name $1;
    root \"$2\";

    index index.html;

    charset utf-8;
    client_max_body_size 100M;

    $rewritesTXT

    location / {
        try_files \$uri \$uri/ /index.html;
        $headersTXT
        $paramsTXT
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/$1-error.log error;

    sendfile off;

    location ~ /\.ht {
        deny all;
    }

    ssl_certificate     /etc/ssl/certs/$1.crt;
    ssl_certificate_key /etc/ssl/certs/$1.key;
}
"

echo "$block" > "/etc/nginx/sites-available/$1"
ln -fs "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/$1"
