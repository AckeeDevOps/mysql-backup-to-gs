# Backup container for mariadb instances

This image provides a cron daemon that runs daily backups from mysql (clustered or single instance) to Google Storage.

Following ENV variables must be specified:
 - `MYSQL_HOST` contains the remote host (hostname or IP) connection string for mysqldump command line client option -h
 - `MYSQL_PORT` contains the remote port number for mysqldump option -P
  - `mysqlserver.domain.com:27017` in case of a single instance
 - `MYSQL_ROOT_PASSWORD` password of user `root` who has access to all dbs. Default value is the value of `MYSQL_PASSWORD`
 - `MYSQL_USER` mysql user, default: `root`
 - `GS_URL` contains address in GS where to store backups, without the `gs://` url prefix
  - `bucket-name/directory`
 - `GS_ACCESS_KEY`
 - `GS_SECRET_KEY`
 - `CRON_SCHEDULE` cron schedule string, default '0 2 * * *'

