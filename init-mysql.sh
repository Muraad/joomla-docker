#!/bin/sh

# Very insecure its a clear text file!
echo "Disabling mysql command history."
# export MYSQL_HISTFILE=/dev/null
# or
rm ~/.mysql_history
ln -s /dev/null ~/.mysql_history

# Create Database for joomla
echo "Creating a database with name joomla_db."
mysql -u root -e "CREATE DATABASE joomla_db"

# set password for (all) root user
#echo "Setting password for (all) root user."
#mysql -u root -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$1'); SET PASSWORD FOR 'root'@'127.0.0.1' = PASSWORD('$1'); SET PASSWORD FOR 'root'@'::1' = PASSWORD('$1');"


# add new user too with username = $1 and password = $2
#if [ $# -eq 2 ]; then
  echo "Enter the database username for the new joomla user"
  read -p "Enter username for joomla mysql user: " user
  
  pw="empty"
  while true
  do
    read -p "Enter new user password: " tmp
    read -p "Enter new user password again: " tmp1
    if [ "$tmp" != "$tmp1" ]; then
      echo "Please try again!"
    else
      echo "Paswords match :)"
      pw=$tmp
      break
    fi
  done  

  echo "Adding new user " "${user}:${pw}"
  mysql -u root -e "GRANT ALL PRIVILEGES ON ${user}_db.* to '$user'@'localhost' IDENTIFIED BY '$pw';"
  mysql -u root -e "GRANT ALL PRIVILEGES ON ${user}_db.* to '$user'@'127.0.0.1' IDENTIFIED BY '$pw';"
  echo "Flushing new privileges."
  mysql -u root -e "FLUSH PRIVILEGES;"
#fi

# call secure installation and got through the setup process.
mysql_secure_installation

echo "Clearing bash history."
history -c

