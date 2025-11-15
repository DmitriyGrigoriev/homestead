#!/usr/bin/env bash

# PyStead Flask Site Configuration
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

# Default Flask port
FLASK_PORT=${3:-5000}

# Create Nginx configuration for Flask
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

    # Static files
    location /static/ {
        alias $2/static/;
        expires 30d;
        add_header Cache-Control \"public, immutable\";
    }

    # Proxy to Flask application
    location / {
        proxy_pass http://127.0.0.1:$FLASK_PORT;
        proxy_http_version 1.1;
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

    # Detect Flask app (app.py or wsgi.py)
    if [ -f "$2/wsgi.py" ]; then
        APP_MODULE="wsgi:app"
    elif [ -f "$2/app.py" ]; then
        APP_MODULE="app:app"
    else
        APP_MODULE="app:app"  # default fallback
        echo "Warning: Could not find wsgi.py or app.py, using default: app:app"
    fi

    # Create supervisor config for Gunicorn
    supervisor_conf="[program:$1-flask]
command=/usr/bin/gunicorn --workers 4 --bind 127.0.0.1:$FLASK_PORT $APP_MODULE
directory=$2
user=vagrant
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/$1-flask.log
environment=FLASK_APP=\"app.py\"
"
    echo "$supervisor_conf" > "/etc/supervisor/conf.d/$1-flask.conf"
    
    supervisorctl reread
    supervisorctl update
    supervisorctl start $1-flask
    
    echo ""
    echo "Flask site configured with Gunicorn (production mode)"
    echo "Supervisor service: $1-flask"
    echo "App module: $APP_MODULE"
    echo "Commands:"
    echo "  sudo supervisorctl status $1-flask"
    echo "  sudo supervisorctl restart $1-flask"
    echo "  sudo supervisorctl tail -f $1-flask"
else
    echo ""
    echo "Flask site configured for development mode"
    echo "To run Flask development server, SSH into the VM and run:"
    echo "  cd $2"
    echo "  export FLASK_APP=app.py"
    echo "  export FLASK_ENV=development"
    echo "  flask run --host=0.0.0.0 --port=$FLASK_PORT"
    echo ""
    echo "For production deployment, add 'prod: true' to your site configuration"
fi
