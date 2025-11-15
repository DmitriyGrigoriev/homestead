#!/usr/bin/env bash

# PyStead FastAPI Site Configuration
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

# Default FastAPI port
FASTAPI_PORT=${3:-8000}

# Create Nginx configuration for FastAPI
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

    # Proxy to FastAPI application
    location / {
        proxy_pass http://127.0.0.1:$FASTAPI_PORT;
        proxy_http_version 1.1;
        
        # WebSocket support
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        
        # Standard proxy headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Additional settings for streaming
        proxy_buffering off;
        proxy_cache off;
        
        # Timeout settings (useful for long-running API calls)
        proxy_connect_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_read_timeout 3600s;
        
        $headersTXT
    }

    # Static files (if any)
    location /static/ {
        alias $2/static/;
        expires 30d;
        add_header Cache-Control \"public, immutable\";
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
    # Install uvicorn if not present
    if ! command -v uvicorn &> /dev/null; then
        echo "Installing uvicorn..."
        pip install "uvicorn[standard]"
    fi

    # Detect main app file (main.py or app.py)
    if [ -f "$2/main.py" ]; then
        APP_MODULE="main:app"
    elif [ -f "$2/app.py" ]; then
        APP_MODULE="app:app"
    else
        APP_MODULE="main:app"  # default fallback
        echo "Warning: Could not find main.py or app.py, using default: main:app"
    fi

    # Create supervisor config for Uvicorn
    supervisor_conf="[program:$1-fastapi]
command=/usr/bin/uvicorn $APP_MODULE --host 0.0.0.0 --port $FASTAPI_PORT --workers 4
directory=$2
user=vagrant
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/$1-fastapi.log
"
    echo "$supervisor_conf" > "/etc/supervisor/conf.d/$1-fastapi.conf"
    
    supervisorctl reread
    supervisorctl update
    supervisorctl start $1-fastapi
    
    echo ""
    echo "FastAPI site configured with Uvicorn (production mode)"
    echo "Supervisor service: $1-fastapi"
    echo "App module: $APP_MODULE"
    echo "Commands:"
    echo "  sudo supervisorctl status $1-fastapi"
    echo "  sudo supervisorctl restart $1-fastapi"
    echo "  sudo supervisorctl tail -f $1-fastapi"
else
    echo ""
    echo "FastAPI site configured for development mode"
    echo "To run FastAPI development server, SSH into the VM and run:"
    echo "  cd $2"
    echo "  uvicorn main:app --reload --host 0.0.0.0 --port $FASTAPI_PORT"
    echo ""
    echo "Or if your app is in app.py:"
    echo "  uvicorn app:app --reload --host 0.0.0.0 --port $FASTAPI_PORT"
    echo ""
    echo "For production deployment, add 'prod: true' to your site configuration"
fi
