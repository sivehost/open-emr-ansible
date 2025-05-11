#!/bin/bash
set -e

echo "Waiting for MariaDB at host '$MYSQL_HOST'..."

until mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e 'SELECT 1'; do
    sleep 2
done

if ! mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e "USE $MYSQL_DATABASE;" 2>/dev/null; then
    echo "Database '$MYSQL_DATABASE' does not exist. Creating and importing..."
    mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE $MYSQL_DATABASE;"
    mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < /tmp/openemrdb.sql
else
    echo "Database '$MYSQL_DATABASE' already exists. Skipping import."
fi

echo "Starting Apache..."
exec apache2ctl -D FOREGROUND
