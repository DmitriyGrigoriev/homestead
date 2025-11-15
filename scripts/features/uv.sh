#!/usr/bin/env bash

if [ -f ~/.homestead-features/wsl_user_name ]; then
    WSL_USER_NAME="$(cat ~/.homestead-features/wsl_user_name)"
    WSL_USER_GROUP="$(cat ~/.homestead-features/wsl_user_group)"
else
    WSL_USER_NAME=vagrant
    WSL_USER_GROUP=vagrant
fi

export DEBIAN_FRONTEND=noninteractive

if [ -f /home/$WSL_USER_NAME/.homestead-features/uv ]
then
    echo "uv already installed."
    exit 0
fi

touch /home/$WSL_USER_NAME/.homestead-features/uv
chown -Rf $WSL_USER_NAME:$WSL_USER_GROUP /home/$WSL_USER_NAME/.homestead-features

# Получение версии из переменной окружения (из Homestead.yaml)
UV_VERSION="${version:-latest}"

# Установка uv (быстрый пакетный менеджер Python)
echo "Installing uv version: $UV_VERSION"
if [ "$UV_VERSION" = "latest" ]; then
    sudo -u $WSL_USER_NAME curl -LsSf https://astral.sh/uv/install.sh | sudo -u $WSL_USER_NAME sh
else
    sudo -u $WSL_USER_NAME curl -LsSf https://astral.sh/uv/$UV_VERSION/install.sh | sudo -u $WSL_USER_NAME sh
fi

# Путь к uv (новая версия устанавливается в .local/bin)
UV_BIN="/home/$WSL_USER_NAME/.local/bin/uv"

# Добавление uv в PATH в .bashrc (если еще не добавлено)
if ! grep -q '.local/bin' /home/$WSL_USER_NAME/.bashrc; then
    echo -e '
# uv package manager' >> /home/$WSL_USER_NAME/.bashrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/$WSL_USER_NAME/.bashrc
fi

# Экспорт PATH для текущей сессии
export PATH="/home/$WSL_USER_NAME/.local/bin:$PATH"

# Установка прав доступа
chown -Rf $WSL_USER_NAME:$WSL_USER_GROUP /home/$WSL_USER_NAME/.local

# Настройка uv: виртуальные окружения в директории проекта
echo "Configuring uv: virtual environments in project directory"
sudo -u $WSL_USER_NAME $UV_BIN config set venv.location .venv

# Опционально: настройка Python версии по умолчанию (если указана)
if [ -n "$python_version" ]; then
    echo "Setting default Python version: $python_version"
    sudo -u $WSL_USER_NAME $UV_BIN python install $python_version
    sudo -u $WSL_USER_NAME $UV_BIN python pin $python_version
fi

echo "uv installed successfully."
