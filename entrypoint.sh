#!/bin/bash -x
#set -eo pipefail

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
fi

# verify gs config - ls bucket
$backup_tool ls "gs://${GS_URL%%/*}" > /dev/null
echo "Google storage bucket access verified."

mkdir -p /tmp/backup/
rm -rf -- /tmp/backup/* 
mysqldump -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --all-databases --single-transaction -h "$MYSQL_HOST" -P "$MYSQL_PORT" --result-file=/tmp/backup/dump.sql --verbose $FORCE
echo $?
gzip /tmp/backup/dump.sql
echo $?

$backup_tool $backup_options /tmp/backup/ gs://$GS_URL/ 
