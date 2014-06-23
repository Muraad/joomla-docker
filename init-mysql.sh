#!/bin/sh

# Very insecure its a clear text file!
echo "Disabling mysql command history."
# export MYSQL_HISTFILE=/dev/null
# or
rm ~/.mysql_history
ln -s /dev/null ~/.mysql_history

# Create Database for joomla
echo "Createing a database with name joomla_db."
mysql -u root -e "CREATE DATABASE joomla_db"

# set password for (all) root user
echo "Setting password for (all) root user."
mysql -u root -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$1'); SET PASSWORD FOR 'root'@'127.0.0.1' = PASSWORD('$1'); SET PASSWORD FOR 'root'@'::1' = PASSWORD('$1');"


# add new user too with username = $2 and password = $3
if [ $# -eq 3 ]
  echo "Adding new user " "$2"
  mysql -u root --password=$1 -e "GRANT ALL PRIVILEGES ON joomla_db.* to '$2'@'localhost' IDENTIFIED BY '$3';"
  mysql -u root --password=$1 -e "GRANT ALL PRIVILEGES ON joomla_db.* to '$2'@'127.0.0.1' IDENTIFIED BY '$3';"
  echo "Flushing new privileges."
  mysql -u root --password=$1 -e "FLUSH PRIVILEGES;"
fi

echo "Clearing bash history."
history -c

