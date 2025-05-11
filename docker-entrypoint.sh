#!/bin/bash
set -e

echo "Waiting for MariaDB at host '$MYSQL_HOST'..."

until mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e 'SELECT 1'; do
    sleep 2
done

echo "Ensuring database '${MYSQL_DATABASE}' exists..."
mysql -h db -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"

echo "Importing only missing tables..."
while read -r statement; do
  if [[ "$statement" =~ ^CREATE\ TABLE\ `([^`]*)` ]]; then
    table="${BASH_REMATCH[1]}"
    echo "Checking if table '$table' exists..."
    exists=$(mysql -h db -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" -N -B -e "SHOW TABLES LIKE '${table}';")
    if [[ -z "$exists" ]]; then
      echo "Importing table '${table}'..."
      echo "$statement" | mysql -h db -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}"
    else
      echo "Table '${table}' already exists. Skipping..."
    fi
  fi
done < <(awk '/^CREATE TABLE /,/;/' /tmp/openemrdb.sql)


echo "Starting Apache..."
exec apache2ctl -D FOREGROUND
