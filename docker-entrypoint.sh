#!/bin/bash
set -e

echo "Waiting for MariaDB at host '$MYSQL_HOST'..."

until mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e 'SELECT 1'; do
    sleep 30
done

if [[ ! -f /var/www/.import_done ]]; then
    echo "Importing database '$MYSQL_DATABASE'..."
    mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
    mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < /tmp/openemrdb.sql
    touch /var/www/.import_done
else
    echo "Import already completed. Skipping."
fi

echo "Starting Apache..."
exec apache2ctl -D FOREGROUND
