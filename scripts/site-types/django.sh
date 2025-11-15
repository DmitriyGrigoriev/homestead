#!/usr/bin/env bash

# PyStead Django Site Configuration
# Parameters:
# $1 - domain (map)
# $2 - project path (to)
# $3 - HTTP port
# $4 - HTTPS port
# $5 - params
# $6 - exec
# $7 - headers
# $8 - rewrites
# $9 - prod

declare -A params=$5
declare -A headers=$7

# Parse headers
headersTXT=""
if [ -n "$7" ]; then
   for element in "${!headers[@]}"
   do
      headersTXT="${headersTXT}
        add_header ${element} ${headers[$element]};"
   done
fi

# Determine if this is production mode
IS_PROD=${9:-false}

# Default Django runserver port is 8000
DJANGO_PORT=${3:-8000}

# Create Nginx configuration for Django
block="server {
    listen 80;
    listen 443 ssl http2;
    server_name $1;

    ssl_certificate     /etc/ssl/certs/$1.crt;
    ssl_certificate_key /etc/ssl/certs/$1.key;

    charset utf-8;
    client_max_body_size 100M;

    access_log /var/log/nginx/$1-access.log;
    error_log  /var/log/nginx/$1-error.log error;

    # Static files location (Django collectstatic)
    location /static/ {
        alias $2/staticfiles/;
        expires 30d;
        add_header Cache-Control \"public, immutable\";
    }

    # Media files location
    location /media/ {
        alias $2/media/;
        expires 7d;
    }

    # Proxy all other requests to Django application
    location / {
        proxy_pass http://127.0.0.1:$DJANGO_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;
        $headersTXT
    }

    # Disable access to sensitive files
    location ~ /\\.(?!well-known).* {
        deny all;
    }
}
"

echo "$block" > "/etc/nginx/sites-available/$1"
ln -fs "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/$1"

# Create supervisor configuration for production mode
if [ "$IS_PROD" = "true" ]; then
    # Install gunicorn if not present
    if ! command -v gunicorn &> /dev/null; then
        echo "Installing gunicorn..."
        pip install gunicorn
    fi

    # Create supervisor config for Gunicorn
    supervisor_conf="[program:$1-django]
command=/usr/bin/gunicorn --workers 4 --bind 127.0.0.1:$DJANGO_PORT wsgi:application
directory=$2
user=vagrant
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/$1-django.log
"
    echo "$supervisor_conf" > "/etc/supervisor/conf.d/$1-django.conf"
    
    supervisorctl reread
    supervisorctl update
    supervisorctl start $1-django
    
    echo ""
    echo "Django site configured with Gunicorn (production mode)"
    echo "Supervisor service: $1-django"
    echo "Commands:"
    echo "  sudo supervisorctl status $1-django"
    echo "  sudo supervisorctl restart $1-django"
    echo "  sudo supervisorctl tail -f $1-django"
else
    echo ""
    echo "Django site configured for development mode"
    echo "To run Django development server, SSH into the VM and run:"
    echo "  cd $2"
    echo "  python manage.py runserver 0.0.0.0:$DJANGO_PORT"
    echo ""
    echo "For production deployment, add 'prod: true' to your site configuration"
fi
