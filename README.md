# Backup container for mariadb instances

This image provides a cron daemon that runs daily backups from mysql (clustered or single instance) to Google Storage.

Following ENV variables must be specified:
 - `MYSQL_HOST` contains the remote host (hostname or IP) connection string for mysqldump command line client option -h
  - `mysql.domain.com`
 - `MYSQL_PORT` contains the remote port number for mysqldump option -P
  - `3306` 
 - `MYSQL_PASSWORD` password of user who has read access to all dbs.
 - `MYSQL_USER` mysql user
 - `GS_URL` contains address in GS where to store backups, without the `gs://` url prefix
  - `bucket-name/directory`