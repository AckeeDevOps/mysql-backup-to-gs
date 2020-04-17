#!/bin/bash

backup_tool="/google-cloud-sdk/bin/gsutil"
backup_options="-m rsync -r"


# verify variables
if [ -z "$GS_URL" -o -z "$MYSQL_HOST" ]; then
    echo >&2 'Backup information is not complete. You need to specify GS_URL, MYSQL_HOST. No backups, no fun.'
    exit 1
fi

FORCE=""
if [ ! -z "$MYSQL_DUMP_FORCE" ]; then
  FORCE="--force"
else
  set -eo pipefail # if we do not force, we want clean exit codes on mysqldump command
fi

if [ ! -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  /google-cloud-sdk/bin/gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
fi

mkdir -p /tmp/backup/
rm -rf -- /tmp/backup/*

for i in `echo "show databases" | mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -P "$MYSQL_PORT" | grep -Ev "^(Database|sys|performance_schema|information_schema|$MYSQL_IGNORE_DBS)$"`; do
  echo $i
  mysqldump -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --databases $i --single-transaction -h "$MYSQL_HOST" -P "$MYSQL_PORT" --result-file=/tmp/backup/${i}_dump.sql --verbose $FORCE || echo "${i} database backup has failed!" >> /tmp/fails
  gzip -v /tmp/backup/${i}_dump.sql || true
done

echo "export done, now gzip output and transfer it to GCS"

$backup_tool $backup_options /tmp/backup/ gs://$GS_URL/

if [ -f /tmp/fails ]; then
  cat /tmp/fails
  exit 1
fi
