#!/usr/bin/env bash

if [ -f ~/.homestead-features/wsl_user_name ]; then
    WSL_USER_NAME="$(cat ~/.homestead-features/wsl_user_name)"
    WSL_USER_GROUP="$(cat ~/.homestead-features/wsl_user_group)"
else
    WSL_USER_NAME=vagrant
    WSL_USER_GROUP=vagrant
fi

export DEBIAN_FRONTEND=noninteractive

if [ -f /home/$WSL_USER_NAME/.homestead-features/poetry ]
then
    echo "Poetry already installed."
    exit 0
fi

touch /home/$WSL_USER_NAME/.homestead-features/poetry
chown -Rf $WSL_USER_NAME:$WSL_USER_GROUP /home/$WSL_USER_NAME/.homestead-features

# Установка Poetry (версия 2.0+)
sudo -u $WSL_USER_NAME curl -sSL https://install.python-poetry.org | sudo -u $WSL_USER_NAME python3 -
# Удаление Poetry:
# curl -sSL https://install.python-poetry.org | POETRY_UNINSTALL=1 python3 -

# Путь к Poetry
POETRY_BIN="/home/$WSL_USER_NAME/.local/bin/poetry"
export PATH="/home/$WSL_USER_NAME/.local/bin:$PATH"

# Обновление Poetry до последней версии
sudo -u $WSL_USER_NAME $POETRY_BIN self update

# Установка плагинов
sudo -u $WSL_USER_NAME $POETRY_BIN self add poetry-plugin-export
sudo -u $WSL_USER_NAME $POETRY_BIN self add poetry-plugin-shell

echo -e 'Настройка poetry: виртуальные окружения в директории проекта'
sudo -u $WSL_USER_NAME $POETRY_BIN config virtualenvs.in-project true

echo -e 'Установка cookiecutter'
sudo -u $WSL_USER_NAME python3 -m pip install --upgrade cookiecutter
