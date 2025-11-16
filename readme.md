<p align="center"><img src="/art/logo.svg" alt="Laravel Homestead Logo"></p>

<p align="center">
    <a href="https://github.com/laravel/homestead/actions">
        <img src="https://github.com/laravel/homestead/workflows/tests/badge.svg" alt="Build Status">
    </a>
    <a href="https://packagist.org/packages/laravel/homestead">
        <img src="https://img.shields.io/packagist/dt/laravel/homestead" alt="Total Downloads">
    </a>
    <a href="https://packagist.org/packages/laravel/homestead">
        <img src="https://img.shields.io/packagist/v/laravel/homestead" alt="Latest Stable Version">
    </a>
    <a href="https://packagist.org/packages/laravel/homestead">
        <img src="https://img.shields.io/packagist/l/laravel/homestead" alt="License">
    </a>
</p>

# PyStead - Среда разработки для Python
## Введение

PyStead - это форк Laravel Homestead, адаптированный для Python-разработки. Это готовая Vagrant box, которая предоставляет отличную среду разработки без необходимости устанавливать Python, веб-сервер или любое другое серверное ПО на вашу локальную машину. Больше не нужно беспокоиться о порче вашей операционной системы! Vagrant boxes полностью одноразовые. Если что-то пойдёт не так, вы можете уничтожить и пересоздать box за несколько минут!
Официальная документация [находится здесь](https://laravel.com/docs/homestead).

### Основные отличия от Laravel Homestead

#### Удалено (специфично для PHP):

- PHP CLI управление версиями
- PHP-FPM конфигурация
- Composer автообновления
- XHGui профилировщик
- PHP параметры в конфигурации сайтов

#### Добавлено (специфично для Python):

- uv - управление версиями Python и быстрая альтернатива pip
- poetry - современный пакетный менеджер
- ruff - быстрый линтер и форматтер
- Готовые шаблоны для Django, Flask, FastAPI

#### Сохранено:

- Все VM провайдеры (VirtualBox, VMware, Hyper-V, Parallels, libvirt)
- Nginx/Apache веб-серверы
- Базы данных (PostgreSQL, MySQL, MongoDB, Redis)
- SSL сертификаты
- Автоматические бэкапы баз данных
- Port forwarding и SSH туннелирование

#### Компоненты

PyStead состоит из двух проектов. Первый - это репозиторий, который представляет собой само приложение Homestead. Приложение представляет собой оболочку для Vagrant, которая является пользователем API гипервизора виртуализации или поставщика, такого как Virtualbox, Hyper-V, VMware или Parallels. Вторая часть Homestead - это *Settler*, который, по сути, представляет собой скрипты на JSON и Bash, позволяющие превратить минималистичную ОС Ubuntu в то, что мы называем *Homestead base box*. Homestead и Settler (он же *Homestead Base / Base Box*) в совокупности дают вам среду разработки Homestead. 

> При первом запуске `vagrant up` будет загружен базовый образ (~2GB). Он сохранится в `~/.vagrant.d/` и будет использоваться повторно.

##### Текущие версии
| Ubuntu LTS | Settler Version | Homestead Version | Branch    | Status               |
|------------|-----------------|-------------------|-----------|----------------------|
| 22.04      | 14.x            | 15.x              | `main`    | Development/Unstable |
| 22.04      | 14.x            | 15.x              | `release` | Stable               |

## Быстрый старт
1. Установка зависимостей
Требуется:

- Vagrant >= 2.2.0
- Один из провайдеров:
  - VirtualBox (бесплатный, рекомендуется)
  - VMware Workstation/Fusion
  - Hyper-V (Windows Pro/Enterprise)
  - Parallels (macOS)

2. Клонирование репозитория
```commandline
git clone https://github.com/DmitriyGrigoriev/homestead.git pystead
cd pystead
```
3. Создание конфигурации
```commandline
# Windows
copy Homestead.yaml.example Homestead.yaml

# Mac/Linux
cp Homestead.yaml.example Homestead.yaml
```
4. Настройка Homestead.yaml
```yaml
ip: "192.168.56.56"
memory: 2048
cpus: 2
provider: virtualbox

authorize: ~/.ssh/id_rsa.pub
keys:
    - ~/.ssh/id_rsa

folders:
    - map: ~/Projects/my-django-app
      to: /home/vagrant/my-django-app

sites:
    - map: myapp.test
      to: /home/vagrant/my-django-app
      type: proxy
      port: 8000

databases:
    - myapp

features:
    - uv:
        version: "latest"
        python_version: "3.11.9"
    - poetry: true
    - mc-htop: true
    - postgresql: true
```
5. Добавление хоста
`Windows (C:\Windows\System32\drivers\etc\hosts):`
```commandline
192.168.56.56  myapp.test
```
6. Запуск
```commandline
vagrant up
```
7. Работа с проектом
```commandline
# Подключение по SSH
vagrant ssh

# Переход в папку проекта
cd ~/my-django-app

# Установка зависимостей
poetry install

# Запуск Django
poetry run python manage.py runserver 0.0.0.0:8000
```

Первый запуск займёт 5-10 минут (загрузка базового образа).

## Python Features

### Нужна конкретная версия Python
```commandline
vagrant ssh

# Установить нужную версию через uv
uv python install 3.10.12

# В проекте указать версию
cd ~/my-project
uv python pin 3.10.12

# Или в Homestead.yaml:
# features:
#     - uv:
#         python_version: "3.10.12"
```

### poetry - Современный пакетный менеджер
```commandline
cd ~/my-project

# Инициализация проекта
poetry init

# Установка зависимостей
poetry add django djangorestframework

# Установка dev-зависимостей
poetry add --group dev pytest black ruff

# Запуск команд в виртуальном окружении
poetry run python manage.py migrate
poetry run pytest

# Активация shell
poetry shell
```
### Настройки poetry:
- Виртуальные окружения создаются в .venv внутри проекта
- Плагин poetry-plugin-export установлен для экспорта в requirements.txt
- Плагин poetry-plugin-shell для улучшенной работы с poetry shell

### uv - Быстрая альтернатива pip
```commandline
# Установка пакетов (в 10-100 раз быстрее pip)
uv pip install django fastapi uvicorn

# Установка из requirements.txt
uv pip install -r requirements.txt

# Обновление всех пакетов
uv pip install --upgrade $(uv pip list | awk '{print $1}')
```

## Сравнение инструментов

### uv vs pip

| Операция                    | pip      | uv        | Ускорение |
|-----------------------------|----------|-----------|-----------|
| Установка Django            | 5.2s     | 0.4s      | 13x       |
| Установка requirements.txt  | 45s      | 1.2s      | 37x       |
| Создание virtualenv         | 2.1s     | 0.1s      | 21x       |

### uv vs pyenv

| Функция                     | pyenv | uv  |
|-----------------------------|-------|-----|
| Установка Python            | ✅    | ✅  |
| Управление виртуальными окружениями | ❌ | ✅  |
| Установка пакетов           | ❌    | ✅  |
| Скорость установки пакетов  | -     | 🚀  |
| Кэширование                 | ❌    | ✅  |

**Вывод:** uv объединяет функциональность pip + pyenv + virtualenv с невероятной скоростью!


### ruff - Быстрый линтер и форматтер
```yaml
# Проверка кода
ruff check .

# Автоисправление
ruff check --fix .

# Форматирование
ruff format .

# Интеграция в pre-commit
# .pre-commit-config.yaml:
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

## Базы данных

### PostgreSQL (рекомендуется для Python)
```yaml
features:
    - postgresql: true

databases:
    - myapp_db
    - testing_db
```

### MySQL/MariaDB
```yaml
features:
    - mysql: true
    # или
    - mariadb: true

databases:
    - myapp
```

### MongoDB
```yaml
features:
    - mongodb: true

databases:
    - myapp
```

### Redis
```yaml
features:
    - redis: true
```

### Переменные окружения
```yaml
variables:
    - key: APP_ENV
      value: development
    - key: DEBUG
      value: "True"
    - key: SECRET_KEY
      value: "django-insecure-dev-key"
    - key: DATABASE_URL
      value: postgresql://homestead:secret@localhost/myapp
    - key: REDIS_URL
      value: redis://localhost:6379/0
```

### Порты
```yaml
ports:
    - send: 54320  # Порт на хосте
      to: 5432     # Порт в VM (PostgreSQL)
    - send: 33060
      to: 3306     # MySQL
    - send: 6380
      to: 6379     # Redis
    - send: 8001   # Дополнительное приложение
      to: 8001
```
## Управление VM
```commandline
# Запуск VM
vagrant up

# Остановка VM
vagrant halt

# Перезагрузка VM
vagrant reload

# Применить изменения конфигурации
vagrant provision

# SSH подключение
vagrant ssh

# Полное удаление VM
vagrant destroy

# Статус VM
vagrant status

# Обновление box (новая версия PyStead)
vagrant box update
```
## Скачать образ VM для локального использования
```commandline
# Скачать virtualbox
vagrant box add laravel/homestead --provider virtualbox --box-version 14.0.2
```

## Проблемы и решения

#### Сайт не открывается
1. Проверьте, запущено ли приложение
```commandline
vagrant ssh
ps aux | grep python
```
2. Проверьте порт
```commandline
netstat -tlnp | grep 8000
```
3. Проверьте Nginx
```commandline
sudo nginx -t
sudo systemctl status nginx
```
4. Проверьте логи:
```commandline
sudo tail -f /var/log/nginx/error.log
```

#### База данных недоступна
```commandline
vagrant ssh

# PostgreSQL
sudo systemctl status postgresql
sudo -u postgres psql -l

# MySQL
sudo systemctl status mysql
mysql -u homestead -psecret -e "SHOW DATABASES;"
```
#### Изменения в Homestead.yaml
```commandline
# Применить изменения без перезагрузки
vagrant provision

# Или с перезагрузкой
vagrant reload --provision
```
#### Медленная работа shared folders (Windows)
Используйте SMB вместо VirtualBox shared folders
```yaml
folders:
    - map: D:\Projects\myapp
      to: /home/vagrant/myapp
      type: "smb"
      smb_username: your_windows_user
      smb_password: your_windows_password
```

### Полезные ссылки
- [Vagrant Documentation](https://www.vagrantup.com/docs/)
- [Poetry Documentation](https://python-poetry.org/docs/)
- [uv Documentation](https://github.com/astral-sh/uv/)

### Благодарности
PyStead основан на Laravel Homestead. Спасибо команде Laravel за отличный инструмент!
