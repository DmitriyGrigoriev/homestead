#!/usr/bin/env bash

if [ ! -d /etc/cron.d ]; then
    mkdir /etc/cron.d
fi

SITE_DOMAIN=$1
SITE_PUBLIC_DIRECTORY=$2
# PyStead: PHP version parameter removed (was $3)

# Note: This creates a basic cron job for Python projects
# For Django: replace with "python manage.py cron_job"
# For custom scripts: replace with your Python script path
# For Celery Beat: use separate celery service instead

# Example cron job - customize for your Python application
cron="* * * * * vagrant  . /home/vagrant/.profile; cd $SITE_PUBLIC_DIRECTORY && python manage.py runcrons >> /dev/null 2>&1"

echo "$cron" > "/etc/cron.d/$SITE_DOMAIN"
