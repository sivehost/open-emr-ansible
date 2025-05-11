#!/bin/bash
set -e

echo "Waiting for MariaDB at host '$MYSQL_HOST'..."
until mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e 'SELECT 1'; do
    sleep 2
done

echo "Ensuring database '${MYSQL_DATABASE}' exists..."
mysql -h db -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"

# Import only if not already done
if [[ ! -f /var/www/.import_done ]]; then
  echo "Importing only missing tables..."
  awk '
    BEGIN { RS=";\n"; ORS=";\n" }
    /^CREATE TABLE/ {
      if (match($0, /CREATE TABLE `([^`]*)`/, arr)) {
        print > "/tmp/table_" arr[1] ".sql"
      }
    }
  ' /tmp/openemrdb.sql

  for table_sql in /tmp/table_*.sql; do
    table=$(basename "$table_sql" .sql | cut -d_ -f2-)
    exists=$(mysql -h db -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" -N -B -e "SHOW TABLES LIKE '${table}';")
    if [[ -z "$exists" ]]; then
      echo "Importing table '${table}'..."
      mysql -h db -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" < "$table_sql"
    else
      echo "Table '${table}' already exists. Skipping..."
    fi
  done

  echo "Marking import as complete."
  touch /var/www/.import_done
else
  echo "Import already completed. Skipping."
fi

echo "Starting Apache..."
exec apache2ctl -D FOREGROUND
