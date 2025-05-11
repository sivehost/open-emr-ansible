#!/bin/bash
set -e

echo "Waiting for MariaDB at host '$MYSQL_HOST'..."
until mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e 'SELECT 1'; do
    sleep 2
done

echo "Ensuring database '${MYSQL_DATABASE}' exists..."
mysql -h "$MYSQL_HOST" -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"

# Import only if not already done
if [[ ! -f /var/www/.import_done ]]; then
  echo "Importing only missing tables..."

  # Get all table names from the SQL dump
  grep -iE "^CREATE TABLE \`" /tmp/openemrdb.sql | while read -r line; do
    table=$(echo "$line" | sed -nE "s/.*CREATE TABLE \`([^`]*)\`.*/\1/p")
    if [[ -n "$table" ]]; then
      echo "Checking if table '$table' exists..."
      exists=$(mysql -h "$MYSQL_HOST" -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" -N -B -e "SHOW TABLES LIKE '${table}';")
      if [[ -z "$exists" ]]; then
        echo "Importing table '${table}'..."
        # Extract the CREATE TABLE block and import it
        sed -n "/CREATE TABLE \`${table}\`/,/);/p" /tmp/openemrdb.sql | mysql -h "$MYSQL_HOST" -u root -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}"
      else
        echo "Table '${table}' already exists. Skipping..."
      fi
    fi
  done

  echo "Marking import as complete."
  touch /var/www/.import_done
else
  echo "Import already completed. Skipping."
fi

echo "Starting Apache..."
exec apache2ctl -D FOREGROUND
