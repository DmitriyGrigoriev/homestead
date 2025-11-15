#!/usr/bin/env bash

# Определение версии PostgreSQL автоматически
PG_VERSION=$(ls /etc/postgresql/ | head -n1)
PG_HBA_CONF="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

IP=$1

# Проверка наличия IP
if [ -z "$IP" ]; then
    echo "Error: IP address required"
    exit 1
fi

# Формирование сети из IP (например, 192.168.56.0/24 из 192.168.56.58)
NETWORK=$(echo $IP | sed 's/\.[0-9]*$/\.0\/24/')

echo "PostgreSQL version: $PG_VERSION"
echo "Configuration file: $PG_HBA_CONF"
echo "Adding network: $NETWORK"

# Проверка наличия записи
if grep -q "$NETWORK" "$PG_HBA_CONF"; then
    echo "Network $NETWORK already exists in $PG_HBA_CONF"
    grep "$NETWORK" "$PG_HBA_CONF"
else
    # Добавление записи (правильный синтаксис pg_hba.conf)
    sudo sh -c "echo 'host    all             all             $NETWORK            md5' >> $PG_HBA_CONF"

    # Проверка успешности добавления
    if grep -q "$NETWORK" "$PG_HBA_CONF"; then
        echo "Successfully added: $NETWORK"

        # Перезагрузка PostgreSQL для применения изменений
        sudo systemctl reload postgresql
        echo "PostgreSQL configuration reloaded"
    else
        echo "Failed to add $NETWORK"
        exit 1
    fi
fi
