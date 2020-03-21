#!/bin/bash
set -eo pipefail

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

candidates=$(echo "show databases" | mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -P "$MYSQL_PORT" | grep -Ev "^(Database|sys|performance_schema|information_schema)$")

mysqldump -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --databases $candidates --single-transaction -h "$MYSQL_HOST" -P "$MYSQL_PORT" --result-file=/tmp/backup/dump.sql --verbose $FORCE
echo $?

echo "export done, now gzip output and transfer it to GCS"

gzip -v /tmp/backup/dump.sql
$backup_tool $backup_options /tmp/backup/ gs://$GS_URL/
