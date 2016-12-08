FROM mariadb:latest

# backups to Amazon S3
RUN apt-get update && apt-get install -y gcc python-dev python-setuptools libffi-dev cron python-pip && pip install gsutil && rm -rf /var/lib/apt/lists/*

# entrypoint
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD touch /var/log/cron.log && cron && tail -f /var/log/cron.log
