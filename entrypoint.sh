#!/bin/bash
set -eo pipefail

backup_tool="gsutil"
backup_options="rsync -r"

# verify variables
if [ -z "$GS_ACCESS_KEY" -o -z "$GS_SECRET_KEY" -o -z "$GS_URL" -o -z "$MYSQL_HOST" -o -z "$MYSQL_PORT" ]; then
  echo >&2 'Backup information is not complete. You need to specify GS_ACCESS_KEY, GS_SECRET_KEY, GS_URL, MYSQL_HOST, MYSQL_PORT. No backups, no fun.'
  echo GS_ACCESS_KEY=$GS_ACCESS_KEY
  echo GS_SECRET_KEY=$GS_SECRET_KEY
  echo GS_URL=$GS_URL
  echo MYSQL_HOST=$MYSQL_HOST
  echo MYSQL_PORT=$MYSQL_PORT
  exit 1
fi

# set gs config
echo -e "[Credentials]\ngs_access_key_id = $GS_ACCESS_KEY\ngs_secret_access_key = $GS_SECRET_KEY" > /root/.boto

# verify gs config - ls bucket
$backup_tool ls "gs://${GS_URL%%/*}" > /dev/null

# set cron schedule TODO: check if the string is valid (five or six values separated by white space)
[[ -z "$CRON_SCHEDULE" ]] && CRON_SCHEDULE='0 2 * * *' && \
   echo "CRON_SCHEDULE set to default ('$CRON_SCHEDULE')"

USER=root
PASSWORD="$MYSQL_ROOT_PASSWORD"
[[ -z "$MYSQL_ROOT_PASSWORD" ]] && PASSWORD="$MYSQL_PASSWORD" && \
   echo "PASSWORD set to MYSQL_PASSWORD. USER is $MYSQL_USER" && USER="$MYSQL_USER"

# add a cron job
echo "$CRON_SCHEDULE root mkdir -p /tmp/backup ; rm -rf /tmp/backup/* && mysqldump -u $USER -p'$PASSWORD' --all-databases --single-transaction --force -h "$MYSQL_HOST" -P "$MYSQL_PORT" --result-file=/tmp/backup/dump.sql --verbose >> /var/log/cron.log 2>&1 && gzip /tmp/backup/dump.sql && $backup_tool $backup_options /tmp/backup/ gs://$GS_URL/ >> /var/log/cron.log 2>&1" >> /etc/crontab
crontab /etc/crontab

exec "$@"
