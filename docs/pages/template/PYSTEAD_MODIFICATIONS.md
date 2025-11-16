# PyStead - Изменения относительно Laravel Homestead

## Обзор
Этот документ описывает изменения, внесённые в Laravel Homestead для создания PyStead - Python-ориентированной среды разработки.

## Дата модификации
2025-11-14

## Удалённые PHP-компоненты из homestead.rb

### 1. PHP CLI Version Management (строка ~263)
**Было:**
```ruby
# Change PHP CLI version based on configuration
if settings.has_key?('php') && settings['php']
  config.vm.provision "Changing PHP CLI Version", type: "shell" do |s|
    s.name = 'Changing PHP CLI Version'
    s.inline = "sudo update-alternatives --set php /usr/bin/php#{settings['php']}; ..."
  end
end
```

**Стало:**
```ruby
# PHP CLI version configuration removed for PyStead (Python-focused fork)
```

**Причина:** PHP CLI больше не нужен в Python-ориентированной среде.

---

### 2. Автоматическая установка PHP из конфигурации сайтов (строка ~285)
**Было:**
```ruby
# Ensure we have PHP versions used in sites in our features
if settings.has_key?('sites')
  settings['sites'].each do |site|
    if site.has_key?('php')
      settings['features'].push({"php" + site['php'] => true})
    end
  end
end
```

**Стало:**
```ruby
# PHP auto-installation from sites removed for PyStead
```

**Причина:** Автоматическое добавление PHP features не требуется.

---

### 3. PHP параметр в конфигурации сайтов (строка ~406)
**Было:**
```ruby
s.args = [
    site['map'],                # $1
    site['to'],                 # $2
    site['port'] ||= http_port, # $3
    site['ssl'] ||= https_port, # $4
    site['php'] ||= '8.3',      # $5  ← УДАЛЕНО
    params ||= '',              # $6
    site['xhgui'] ||= '',       # $7  ← УДАЛЕНО (PHP profiler)
    site['exec'] ||= 'false',   # $8
    headers ||= '',             # $9
    rewrites ||= '',            # $10
    site['prod'] ||=''          # $11
]
```

**Стало:**
```ruby
s.args = [
    site['map'],                # $1
    site['to'],                 # $2
    site['port'] ||= http_port, # $3
    site['ssl'] ||= https_port, # $4
    params ||= '',              # $5 (was $6, PHP removed)
    site['exec'] ||= 'false',   # $6 (was $8, xhgui removed)
    headers ||= '',             # $7 (was $9)
    rewrites ||= '',            # $8 (was $10)
    site['prod'] ||=''          # $9 (was $11)
]
```

**Причина:** Убраны PHP-специфичные параметры: версия PHP и xhgui профилировщик.

**ВАЖНО:** Все site-type скрипты в `scripts/site-types/` должны быть обновлены для новой последовательности аргументов!

---

### 4. XHGui профилировщик PHP (строки ~483-497)
**Было:**
```ruby
if site['xhgui'] == 'true'
  config.vm.provision 'shell' do |s|
    s.path = script_dir + '/features/mongodb.sh'
  end
  # ... установка xhgui
else
  config.vm.provision 'shell' do |s|
    s.inline = 'rm -rf ' + site['to'].to_s + '/xhgui'
  end
end
```

**Стало:**
```ruby
# xhgui (PHP profiler) removed for PyStead
```

**Причина:** XHGui - это профилировщик для PHP приложений, не нужен для Python.

---

### 5. PHP в Cron Schedule (строка ~502)
**Было:**
```ruby
s.args = [site['map'].tr('^A-Za-z0-9', ''), site['to'], site['php'] ||= '']
```

**Стало:**
```ruby
s.args = [site['map'].tr('^A-Za-z0-9', ''), site['to']]
```

**Причина:** PHP версия не нужна для Python cron задач.

**ВАЖНО:** Скрипт `scripts/cron-schedule.sh` должен быть обновлён для работы без PHP параметра!

---

### 6. PHP-FPM переменные окружения (строки ~520-576)
**Было:**
```ruby
if settings.has_key?('variables')
  settings['variables'].each do |var|
    # 10 блоков для разных версий PHP-FPM (5.6, 7.0-7.4, 8.0-8.3)
    config.vm.provision 'shell' do |s|
      s.inline = "echo \"\nenv[$1] = '$2'\" >> /etc/php/5.6/fpm/pool.d/www.conf"
      s.args = [var['key'], var['value']]
    end
    # ... и так для каждой версии PHP
    
    # Экспорт в .profile
    config.vm.provision 'shell' do |s|
      s.inline = "echo \"\n# Set Homestead Environment Variable\nexport $1=$2\" >> /home/vagrant/.profile"
      s.args = [var['key'], var['value']]
    end
  end

  # Перезапуск всех PHP-FPM сервисов
  config.vm.provision 'shell' do |s|
    s.inline = 'service php5.6-fpm restart; service php7.0-fpm restart; ...'
  end
end
```

**Стало:**
```ruby
if settings.has_key?('variables')
  settings['variables'].each do |var|
    # PHP-FPM configuration removed for PyStead
    # Only export environment variables to .profile
    config.vm.provision 'shell' do |s|
      s.inline = "echo \"\n# Set PyStead Environment Variable\nexport $1=$2\" >> /home/vagrant/.profile"
      s.args = [var['key'], var['value']]
    end
  end
end
```

**Причина:** PHP-FPM не используется, переменные окружения экспортируются только в shell профиль.

---

### 7. Composer обновления (строки ~678-682)
**Было:**
```ruby
# Update Composer On Every Provision
config.vm.provision 'shell' do |s|
  s.name = 'Update Composer'
  s.inline = 'sudo chown -R vagrant:vagrant /usr/local/bin && sudo -u vagrant /usr/bin/php8.3 /usr/local/bin/composer self-update --no-progress && sudo chown -R vagrant:vagrant /home/vagrant/.config/'
  s.privileged = false
end
```

**Стало:**
```ruby
# Composer updates removed for PyStead (use pip, poetry, or uv instead)
```

**Причина:** Composer - это PHP пакетный менеджер. Для Python используются pip, poetry, uv.

---

## Что НЕ было изменено

Следующие компоненты остались без изменений, так как они универсальны и полезны для Python-разработки:

1. ✅ **Конфигурация VM** (VirtualBox, VMware, Hyper-V, Parallels, libvirt)
2. ✅ **Сетевые настройки** (приватные сети, порты)
3. ✅ **SSH конфигурация** (ключи, авторизация)
4. ✅ **Shared folders** (синхронизация папок с хостом)
5. ✅ **Nginx/Apache сайты** (веб-серверы нужны для Python web-приложений)
6. ✅ **SSL сертификаты** (нужны для HTTPS)
7. ✅ **Features система** (можно использовать для Python-компонентов)
8. ✅ **Services управление** (systemd enable/disable/start/stop)
9. ✅ **Базы данных** (MySQL/MariaDB, PostgreSQL, MongoDB, etc.)
10. ✅ **Minio buckets** (S3-совместимое хранилище)
11. ✅ **Ngrok конфигурация** (туннелирование)
12. ✅ **Database backup** (бэкапы перед destroy)

---

## Необходимые дополнительные изменения

### Критичные (требуют обновления):

1. **`scripts/site-types/*.sh`** - Все скрипты типов сайтов должны быть обновлены:
   - Убрать использование параметра `$5` (PHP версия)
   - Убрать использование параметра `$7` (xhgui)
   - Пересчитать индексы оставшихся параметров
   - Добавить поддержку Python web-фреймворков (Django, Flask, FastAPI)

2. **`scripts/cron-schedule.sh`** - Обновить для работы без PHP:
   - Убрать третий параметр (PHP версия)
   - Использовать Python для выполнения задач

3. **`scripts/clear-variables.sh`** - Должен очищать только .profile, не PHP-FPM конфиги

### Рекомендуемые (улучшения):

4. **Создать новые site-types для Python:**
   - `scripts/site-types/django.sh`
   - `scripts/site-types/flask.sh`
   - `scripts/site-types/fastapi.sh`
   - `scripts/site-types/streamlit.sh`

5. **Обновить features:**
   - Убрать `scripts/features/php*.sh` (или оставить для обратной совместимости)
   - Улучшить `scripts/features/python.sh`
   - Улучшить `scripts/features/poetry.sh`
   - Улучшить `scripts/features/pyenv.sh`

6. **Документация:**
   - Обновить `readme.md` для PyStead
   - Создать `Homestead.yaml.example` для Python-проектов
   - Добавить примеры конфигурации

---

## Python-специфичные features (уже есть в Homestead)

Следующие features уже доступны и полезны для Python:

- ✅ `pyenv` - управление версиями Python
- ✅ `poetry` - Python пакетный менеджер
- ✅ `uv` - быстрая альтернатива pip
- ✅ `ruff` - быстрый линтер для Python
- ✅ `python` - базовая установка Python

---

## Тестирование изменений

Для проверки работоспособности:

1. Обновить `Homestead.yaml` без PHP параметров
2. Запустить `vagrant up` или `vagrant provision`
3. Проверить, что не возникает ошибок связанных с PHP
4. Создать тестовый Python сайт с новой конфигурацией

---

## Следующие шаги

1. ✅ Удалить PHP-компоненты из `homestead.rb` (ВЫПОЛНЕНО)
2. ⏳ Обновить site-type скрипты
3. ⏳ Обновить cron-schedule.sh
4. ⏳ Создать Python site-types
5. ⏳ Обновить документацию
6. ⏳ Создать примеры конфигурации
7. ⏳ Протестировать на реальных Python-проектах

---

## Совместимость

**Обратная совместимость:** Частично нарушена. Старые конфигурации с PHP параметрами будут работать, но PHP-специфичные функции будут проигнорированы.

**Рекомендация:** Создать отдельную ветку для PyStead и поддерживать её независимо от upstream Laravel Homestead.
