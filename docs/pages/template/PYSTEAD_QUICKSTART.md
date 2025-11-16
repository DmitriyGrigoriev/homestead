# PyStead - Быстрый старт

## Что это?
PyStead - это форк Laravel Homestead, адаптированный для Python-разработки. Vagrant box для создания виртуальной среды разработки Python без установки на локальную машину.

## Основные отличия от Laravel Homestead

### ❌ Удалено (PHP-специфичное)
- PHP CLI управление версиями
- PHP-FPM конфигурация
- Composer автообновления
- XHGui профилировщик
- PHP параметры в site конфигурации

### ✅ Сохранено (универсальное)
- Все VM провайдеры (VirtualBox, VMware, Hyper-V, etc.)
- Nginx/Apache веб-серверы
- Базы данных (MySQL, PostgreSQL, MongoDB, etc.)
- Python features: pyenv, poetry, uv, ruff
- SSL сертификаты
- Shared folders
- Port forwarding
- Backup система

## Установка

```bash
# 1. Клонировать репозиторий
git clone https://github.com/your-username/pystead.git
cd pystead

# 2. Установить Vagrant и VirtualBox (если ещё не установлены)
# https://www.vagrantup.com/downloads
# https://www.virtualbox.org/wiki/Downloads

# 3. Создать конфигурацию
copy Homestead.yaml.example Homestead.yaml

# 4. Отредактировать Homestead.yaml под ваш проект

# 5. Запустить VM
vagrant up
```

## Пример Homestead.yaml для Python

```yaml
ip: "192.168.56.56"
memory: 2048
cpus: 2
provider: virtualbox
name: pystead

authorize: ~/.ssh/id_rsa.pub
keys:
    - ~/.ssh/id_rsa

folders:
    - map: ~/Projects/my-python-app
      to: /home/vagrant/my-python-app

sites:
    - map: myapp.test
      to: /home/vagrant/my-python-app/public
      type: proxy  # Для Python приложений используйте proxy
      port: 8000   # Порт вашего Python приложения

databases:
    - myapp

features:
    - python: true
    - poetry: true
    - pyenv: true
    - ruff: true
    - postgresql: true

# Environment variables
variables:
    - key: DATABASE_URL
      value: postgresql://homestead:secret@localhost/myapp
    - key: DEBUG
      value: "True"
```

## Python Features

### pyenv - Управление версиями Python
```bash
vagrant ssh
pyenv install 3.12.0
pyenv global 3.12.0
python --version
```

### poetry - Пакетный менеджер
```bash
cd /home/vagrant/my-python-app
poetry install
poetry run python manage.py runserver 0.0.0.0:8000
```

### uv - Быстрая альтернатива pip
```bash
uv pip install django
uv pip install fastapi uvicorn
```

### ruff - Быстрый линтер
```bash
ruff check .
ruff format .
```

## Типы сайтов для Python

### Proxy (рекомендуется)
```yaml
sites:
    - map: myapp.test
      to: /home/vagrant/my-python-app
      type: proxy
      port: 8000  # Порт вашего Python приложения
```

Затем запустите ваше приложение:
```bash
# Django
python manage.py runserver 0.0.0.0:8000

# Flask
flask run --host=0.0.0.0 --port=8000

# FastAPI
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Static (для статических сайтов)
```yaml
sites:
    - map: docs.test
      to: /home/vagrant/my-docs/build
      type: spa  # Single Page Application
```

## Управление VM

```bash
# Запуск
vagrant up

# Остановка
vagrant halt

# Перезагрузка
vagrant reload

# Применить изменения конфигурации
vagrant provision

# SSH подключение
vagrant ssh

# Удалить VM
vagrant destroy

# Статус
vagrant status
```

## Базы данных

### PostgreSQL (рекомендуется для Python)
```yaml
features:
    - postgresql: true

databases:
    - myapp_db
```

Подключение:
```python
# Django settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'myapp_db',
        'USER': 'homestead',
        'PASSWORD': 'secret',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

### MySQL
```yaml
features:
    - mysql: true
    # или
    - mariadb: true
```

### MongoDB
```yaml
features:
    - mongodb: true
```

## PM2 для Node.js приложений

Если вы также работаете с Node.js:

```yaml
sites:
    - map: nodeapp.test
      to: /home/vagrant/nodeapp
      type: proxy
      port: 3000
      pm2:
        - name: "my-node-app"
          script: "npm"
          args: "start"
          cwd: "/home/vagrant/nodeapp"
```

## Переменные окружения

```yaml
variables:
    - key: APP_ENV
      value: development
    - key: SECRET_KEY
      value: "your-secret-key"
    - key: DATABASE_URL
      value: postgresql://homestead:secret@localhost/myapp
```

Переменные автоматически экспортируются в `~/.profile`.

## Cron задачи

```yaml
sites:
    - map: myapp.test
      to: /home/vagrant/my-python-app
      schedule: true  # Включает Laravel scheduler
```

**Примечание:** Для Python cron задач лучше использовать системный cron или Celery.

## Бэкапы баз данных

```yaml
backup: true
```

При выполнении `vagrant destroy` будут автоматически созданы бэкапы баз данных в `.backup/`.

## Проблемы и решения

### Сайт не открывается
1. Проверьте, запущено ли ваше Python приложение: `vagrant ssh` → `ps aux | grep python`
2. Проверьте порт: `netstat -tlnp | grep 8000`
3. Проверьте Nginx конфигурацию: `sudo nginx -t`

### База данных недоступна
```bash
vagrant ssh
sudo systemctl status postgresql
# или
sudo systemctl status mysql
```

### Изменения в Homestead.yaml не применяются
```bash
vagrant reload --provision
```

## Полезные команды внутри VM

```bash
vagrant ssh

# Проверить версию Python
python --version

# Установить пакеты
pip install package-name
poetry add package-name
uv pip install package-name

# Проверить сервисы
sudo systemctl status nginx
sudo systemctl status postgresql

# Логи Nginx
sudo tail -f /var/log/nginx/error.log

# Логи приложения (если используется supervisor)
sudo tail -f /var/log/supervisor/my-app.log
```

## Дополнительно

### Добавить хост на локальной машине

**Windows:** Отредактируйте `C:\Windows\System32\drivers\etc\hosts`
```
192.168.56.56  myapp.test
```

**Mac/Linux:** Отредактируйте `/etc/hosts`
```
192.168.56.56  myapp.test
```

### Доступ к базе данных с хоста

```yaml
ports:
    - send: 54320
      to: 5432  # PostgreSQL
    - send: 33060
      to: 3306  # MySQL
```

Затем подключайтесь: `localhost:54320`

## Документация

- [Полные изменения от Homestead](./PYSTEAD_MODIFICATIONS.md)
- [Laravel Homestead Docs](https://laravel.com/docs/homestead) (для справки)

## Поддержка

Если вы нашли баг или у вас есть предложение, создайте Issue в репозитории.
