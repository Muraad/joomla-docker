#!/bin/sh

########################################################################
#	Script is started with argument "debug".                       #
########################################################################

if [ $1 = "debug" ] ; then
  echo "Doing nothing, going to bash..."
  /bin/bash
  exit 0
fi

########################################################################
#	Start the supervisord.                                         #
#	This is usefull if container was started with "debug".         #
#	Typing /tmp/setup.sh start is shorter than                     #
#	/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf#
########################################################################
	 
if [ $1 = "start" ]; then
  echo "Starting supervisord..."
  /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
  exit 0
fi

########################################################################
#	Script is started with argument "backup".                      #
#	- The container should be started with mounted volumes from    #
#	  another running joomla/nginx contianer.                      #
#       - A host folder should be mounted under /backup                #
#	Normally the backup-joomla.sh script should be used            #
#       from a host to backup a joomla/nginx container.                #
#       So this does not have to be called manually.                   #
########################################################################

if [ $1 = "backup" ] ; then
# $1 - The container name (joomla/nginx) where to take the backups from
  mkdir /backup/backup
  
  echo "Creating a backup..."

  if [ -d /var/mysql ]; then
    echo "Creating mysql-backup.tar"
    tar cf /backup/backup/mysql-backup.tar /var/mysql
  fi
 
  if [ -d /var/www/vhosts ]; then
    echo "Creating vhosts-www-backup.tar"
    tar cf /backup/backup/vhosts-www-backup.tar /var/www/vhosts
  fi

  if [ -d /etc/nginx/ssl ]; then
    echo "Creating ssl-bakup.tar"
    tar cf /backup/backup/ssl-backup.tar /etc/nginx/ssl
  fi
  
  if [ -d /etc/nginx/sites-available ]; then
    echo "Creating sites-available-backup.tar"
    tar cf /backup/backup/sites-available-backup.tar /etc/nginx/sites-available
  fi

  if [ -d /etc/php5/fpm/pool.d ] ; then
    echo "Creating fpm-pool.tar"
    tar cf /backup/backup/fpm-pool-backup.tar /etc/php5/fpm/pool.d
  fi

  exit 0
fi

################################################################################
#                                                                              #
#				START SETUP				       #
################################################################################

# Be sure a data directory for the vhosts www data and for mysql (mariaDb) is set.
JOOMLA_DATA=${JOOMLA_DATA:-/var/www/vhosts}
MYSQL_DATA=${MYSQL_DATA:-/var/mysql}

echo "Creating the supervisor log directory"
mkdir -p /var/log/supervisor

echo "Creating the vhosts www data directory"
mkdir -p $JOOMLA_DATA

echo "Creating directory for php-fpm pool unix sockets"
mkdir -p /var/run

echo "Creating directory for the mysql data"
mkdir -p $MYSQL_DATA

echo "Creating directory for the running mysql daemon and"
echo "set correct owner ship and permissions"
mkdir -p /var/run/mysqld; chown mysql:mysql /var/run/mysqld

echo "Creating directory for the running ssh daemon and"
echo "setting correct owner ship and permissions"
mkdir -p /var/run/sshd; chmod 0755 /var/run/sshd; chown root:root /var/run/sshd

# INFO: correct ownership for $JOOMLA_DATA and $MYSQL_DATA 
# INFO: folders is set at the end of the script. So no sudo has to be used during setup...

# This file was existing on my ubuntu image
echo "delete /etc/nologin if existing, this would prevent ssh from working."
rm --interactive=never /etc/nologin


##########################################################################
#       SSH setup                                                        #
##########################################################################

# Username = ssh-user, Password = ssh-user
# Add him to sudoers will access to everything without password.
# set its default bash to /bin/bash.
# TODO: set "AllowRootLogin no" and "AllowUsers ssh-user"
echo "Adding user ssh-user."
useradd -m ssh-user && echo 'ssh-user:ssh-user' | chpasswd && echo 'ssh-user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers; usermod -s /bin/bash ssh-user

echo "setting up sshd to allow passwords."
sed -i 's/PermitEmptyPasswords.*/PermitEmptyPasswords yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# this is needed for sshd to work with docker. There was a 
# strange error. The ssh from host to container was closing directly after successfull login via password.
echo "Fixing /etc/pam.d/sshd for docker. Deactivating session required pam_loginuid.so"
sed -i 's/session.*required.*pam_loginuid.so/#session    required     pam_loginuid.so/' /etc/pam.d/sshd


# get root password from environment varible ROOT_PW
# if it is set, otherwise use default password "root"
# ssh into container after starting and change it!!
# TODO: Is environtment variable safe? Maybe clear it after root pw is set?!

echo "Setting root password"
$rootpw = ${ROOT_PW:-root}
# set the root password
echo 'root:'${rootpw}'' |chpasswd


##########################################################################
#       MariaDb config                                                   #
##########################################################################

echo "Configure maria db to use our MYSQL_DATA directory."
#RUN sed -i 's/^innodb_flush_method/#innodb_flush_method/' /etc/mysql/my.cnf &&\
sed -i -e 's/^datadir\s*=.*/datadir = \/var\/mysql/' /etc/mysql/my.cnf

 
###########################################################################
#this is neeeded to "repair" the data tables and everything               #
###########################################################################

#echo "Running mysql_install_db to fix tables."
#mysql_install_db

if [ ! -d /var/mysql/mysql ]; then
  echo "Running mysql_install_db..."
  mysql_install_db --user=mysql
fi

###########################################################################
#	SSL (HTTPS setup                                                  #
###########################################################################
echo "Creating directory /etc/nginx/ssl/vhosts for ssl keys and certificates."
mkdir -p /etc/nginx/ssl/vhosts


#########################################################################
#	Setting scripts executable.                                     #
#########################################################################
echo "Setting /tmp/init-mysql.sh executable."
echo "INFO: Call it after first container start to set mysql passwords."
chmod u+rx /tmp/init-mysql.sh

echo "Setting /tmp/secure-joomla.sh executable."
echo "INFO: Call it after joomla web installation to harden permissions."
chmod u+rx /tmp/secure-joomla.sh

echo "Setting setup-joomla-vhost.sh executable."
chmod u+rx  /tmp/setup-joomla-vhost.sh     


##########################################################################
#	Script was started with argument "setup-joomla".                 #
#       -> Create the first joomla vhost.                                #
##########################################################################
if [ $1 = "setup-joomla" ]; then
  echo "Running setup-joomla-vhost.sh."
  /tmp/setup-joomla-vhost.sh
fi


###########################################################################
#	Check if data for                                                 #
#       - sites-available                                                 #
#       - vhosts                                                          #
#       - ssl                                                             #
#       - mysql                                                           #
#	- php-fpm pool configurations
#	is present in /tmp/, mounted via VOLUME´s.                        #
###########################################################################

if [ -d /tmp/sites-available ]; then
  echo "Copy everything from /tmp/sites-available to /etc/nginx/sites-available to fix permissions..."
  cp -R /tmp/sites-available/* /etc/nginx/sites-available/
  rm --interactive=never -R /tmp/sites-availabe
fi

if [ -d /tmp/vhosts ]; then
  echo "Copy everything from /tmp/vhosts to /var/www/vhosts..."
  sudo -u www-data cp -R /tmp/vhosts/* /var/www/vhosts/
  rm --interactive=never -R /tmp/sites-available
fi

if [ -d /tmp/ssl ]; then
  echo "Copy everything from /tmp/ssl to /etc/nginx/ssl/..."
  sudo -u www-data cp -R /tmp/ssl/* /etc/nginx/ssl/
  rm --interactive=never -R /tmp/ssl
fi

if [ -d /tmp/mysql ]; then
  echo "Copy everything from /tmp/mysql to /var/mysql..."
  sudo -u mysql cp /tmp/mysql/* /var/mysql
  rm --interactive=never -R /tmp/mysql
fi

if [ -d /tmp/php-fpm-pools ]; then
  echo "Copy everything from /tmp/php-fpm-pools to /etc/php5/fpm/pool.d/"
  cp -R /tmp/php-fpm-pools/* /etc/php5/fpm/pool.d/
fi

###########################################################################
#       Removing default in sites-enabled                                 #
###########################################################################
echo "Removing default site in /etc/nginx/sites-enabled."
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default


###########################################################################
#	Restoring from /tmp/backup if available.                          #
###########################################################################

if [ -f /tmp/backup/mysql-backup.tar ] ; then
  echo "Restoring mariaDb (mysql) data."
  tar -C / -xvf /tmp/backup/mysql-backup.tar
  #rm -f /tmp/backup/mysql-backup.tar
fi 

if [ -f /tmp/backup/vhosts-www-backup.tar ] ; then
  echo "Restoring vhosts www data to /var/www/vhosts."
  tar -C / -xvf /tmp/backup/vhosts-www-backup.tar
  #rm -f /tmp/backup/vhosts-www-backup.tar
fi

if [ -f /tmp/backup/ssl-backup.tar ] ; then
  echo "Restoring ssl keys and certificates to /etc/nginx/ssl."
  tar -C / -xvf /tmp/backup/ssl-backup.tar
  #rm -f /tmp/backup/ssl-backup.tar
fi

if [ -f /tmp/backup/sites-available-backup.tar ] ; then
  echo "Restoring vhost configuration files to /etc/nginx/sites-available."
  tar -C / -xvf /tmp/backup/sites-available-backup.tar
  #rm -f /tmp/backup/sites-available-backup.tar
fi

if [ -f /tmp/backup/fpm-pool-backup.tar ] ; then
  echo "Restoring vhosts php-fpm pool configurations to /etc/php5/fpm/pool.d."
  tar -C / -xvf /tmp/backup/fpm-pool-backup.tar
  #rm -f /tmp/backup/fpm-pool-backup.tar
fi


############################################################################
#	Setting ownership and permissions for                              #
#	- /var/www/vhosts                                                  #
#	- /var/mysql                                                       #
############################################################################

echo "Setting ownership of $JOOMLA_DATA to www-data:www-data ..."
chown -R www-data:www-data $JOOMLA_DATA

echo "Setting permissions for $JOOMLA_DATA to 0755..."
chmod 0755 $JOOMLA_DATA

echo "Setting ownership for $MYSQL_DATA to mysql:mysql..."
chown mysql:mysql $MYSQL_DATA
chmod 700 $MYSQL_DATA


############################################################################
#	Setting up php.ini                                                 #
############################################################################


sed -i -e 's/^datadir\s*=.*/datadir = \/var\/mysql/' /etc/mysql/my.cnf


echo "Enabling all available sites via symlinks to /etc/nginx/sites-enabled/"
ln -s /etc/nginx/sites-available/* /etc/nginx/sites-enabled/

echo "Starting supervisord."
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
