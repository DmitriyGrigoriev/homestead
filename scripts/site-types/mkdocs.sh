#!/usr/bin/env bash

# $1 → домен (например mydocs.test)
# $2 → путь к проекту на VM (например /home/vagrant/code/my-docs)
# $3 → HTTP-порт (80 или 8111 при load_balancer)
# $4 → HTTPS-порт (443 или 8112)
# $5 → params (не используется для mkdocs, но оставляем для совместимости)
# $6 → exec (игнорируем)
# $7 → headers (можно использовать)
# $8 → rewrites (можно использовать)
# $9 → prod (если "1" или "true" — собираем с --clean и без dev-адресов)

DOMAIN=$1
PROJECT_PATH=$2
HTTP_PORT=$3
HTTPS_PORT=$4
PROD=${9:-false}

# Папка, куда MkDocs кладёт готовый сайт
SITE_DIR="$PROJECT_PATH/site"

echo "Creating MkDocs static site configuration for $DOMAIN"
echo "   Project path: $PROJECT_PATH"
echo "   Output dir:   $SITE_DIR"

# 1. Собираем сайт один раз при provision
if [ ! -d "$SITE_DIR" ] || [ "$PROD" = "1" ] || [ "$PROD" = "true" ]; then
    echo "Building MkDocs site..."
    cd "$PROJECT_PATH" || exit 1

    # Если есть pyproject.toml или poetry.lock — используем poetry
    # Если есть requirements.txt — используем pip
    # Иначе просто mkdocs (уже установлен в box’е PyStead/Homestead)

    if [ -f "poetry.lock" ] || [ -f "pyproject.toml" ]; then
        poetry install --no-dev --quiet
        poetry run mkdocs build --clean
    elif [ -f "requirements.txt" ]; then
        pip install -r requirements.txt --quiet
        mkdocs build --clean
    else
        mkdocs build --clean
    fi
else
    echo "Re-using existing build (run with prod: true to force rebuild)"
    cd "$PROJECT_PATH" || exit 1
    mkdocs build  # обычная сборка без --clean
fi

# 2. Создаём nginx-конфиг для чистой статики
cat > /etc/nginx/sites-available/"$DOMAIN" <<EOF
server {
    listen ${HTTP_PORT};
    listen [::]:${HTTP_PORT};
    server_name $DOMAIN;

    root $SITE_DIR;
    index index.html;

    # Красивые URL без .html (если в mkdocs.yml стоит use_directory_urls: true — это уже работает)
    location / {
        try_files \$uri \$uri/ \$uri.html =404;
    }

    # Кеширование статических ассетов
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Опционально: передаём кастомные заголовки, если они пришли в $7
    $7
}

server {
    listen ${HTTPS_PORT} ssl;
    listen [::]:${HTTPS_PORT} ssl;
    server_name $DOMAIN;

    root $SITE_DIR;
    index index.html;

    ssl_certificate     /etc/nginx/ssl/$DOMAIN.crt;
    ssl_certificate_key /etc/nginx/ssl/$DOMAIN.key;

    location / {
        try_files \$uri \$uri/ \$uri.html =404;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Те же заголовки для HTTPS
    $7
}
EOF

# 3. Включаем сайт
ln -sf /etc/nginx/sites-available/"$DOMAIN" /etc/nginx/sites-enabled/"$DOMAIN"

echo "MkDocs site $DOMAIN → $SITE_DIR готов и подключён к Nginx"