#!/bin/bash

# to be sure $JOOMLA_VERSION is set
JOOMLA_VERSION=${JOOMLA_VERSION:-3.3.1}
SERVER_NAME=${SERVER_NAME:-${1}}
WWW_PATH=${WWW_PATH:-/var/www/vhosts}
HTTPS_ON=${HTTPS_ON:-true}

vhost_ssl_path=/etc/nginx/ssl/vhosts/${SERVER_NAME}
ssl_key=${vhost_ssl_path}/${SERVER_NAME}.key
ssl_csr=${vhost_ssl_path}/${SERVER_NAME}.csr
ssl_crt=${vhost_ssl_path}/${SERVER_NAME}.crt
ssl_dhp=${vhost_ssl_path}/${SERVER_NAME}.pem
vhost_config=/etc/nginx/sites-available/${SERVER_NAME}
vhost_www_path=${WWW_PATH}/${SERVER_NAME}
vhost_pool=/etc/php5/fpm/pool.d/${SERVER_NAME}-fpm.conf

#############################################################################
#	Setup the joomla.vhost.tempalte in /etc/nginx/sites-available/      #
#############################################################################
# SERVER_NAME could be "example.com"
if [ "$HTTPS_ON" = "true" ]; then
  echo "Copy joomla.vhost.template to $vhost_config ."
  cp /tmp/joomla.vhost.template $vhost_config
else 
  echo "Copy joomla.vhost.http.template to $vhost_config ."
  cp /tmp/joomla.vhost.http.template $vhost_config
fi 


#############################################################################
#	Create www data directory for the vhost.                            #
#############################################################################

# create html folder for this joomla vhost
echo "Creating directory ${vhost_www_path}/httpdocs."
mkdir -p ${vhost_www_path}/httpdocs

# create the log directory for the vhost
echo "Creating directory ${vhost_www_path}/logs."
mkdir -p ${vhost_www_path}/logs

# TODO: currently this is done in the Dockerfile
# TODO: because there is only one user www-data and currently no 
# TODO: individual user per vhost.
# set owner ship and access rights of 
#chown -R www-data:www-data $vhost_www_path
#chmod 0755 $vhost_www_path

############################################################################
#	Unzip joomla to vhosts www dat directory.                          #
############################################################################

# unzip the downloaded joomla tar to /var/www/vhosts/$SERVER_NAME/httpdocs
echo "Unzipping Joomla_${JOOMLA_VERSION}-Stable-Full_Package.tar.bz2 to ${vhost_www_path}/httpdocs."
tar xjf Joomla_${JOOMLA_VERSION}-Stable-Full_Package.tar.bz2  -C ${vhost_www_path}/httpdocs

# set server name in vhost template
# it will set 
#   server_name 	.$SERVER_NAME
#   root		/var/www/vhosts/$SERVER_NAME/httpdocs
#   fastcgi_pass	unix:/var/run/$SERVER_NAME-fpm.sock
#   access_log/errorlog		/var/www.vhosts/$SERVER_NAME/logs/access/error.log


############################################################################
#	Apply $SERVER_NAME to the vhost template.                          #
############################################################################

echo "Setting $SERVER_NAME in $vhost_config ."
sed 's/{{SERVER_NAME}}/'"${SERVER_NAME}"'/' -i $vhost_config


#############################################################################
#	Apply SSL settings to the vhost template.                           #
#############################################################################

if [ "$HTTPS_ON" = "true" ]; then
  # path to ssl certificate
  echo "Setting $ssl_crt in $vhost_config ."
  sed "s|{{SSL_CRT}}|$ssl_crt|" -i $vhost_config

  # path to ssl key
  echo "Setting $ssl_key in $vhost_config ."
  sed "s|{{SSL_KEY}}|$ssl_key|" -i $vhost_config

  # path to ssl diffie hellman parameter
  echo "Setting $ssh_dhp in $vhost_config ."
  sed "s|{{SSL_DH}}|$ssl_dhp|" -i $vhost_config

fi


############################################################################
#	Setup php-fpm pool configuration for the vhost                     #
############################################################################
echo "Copy www.conf.template to $vhost_pool . "
cp /tmp/www.conf.template $vhost_pool

# this will set pool name to $SERVER_NAME
# [$SERVER_NAME]
# and 
# listen /var/run/$SERVER_NAME-fpm.soch
echo "Setting $SERVER_NAME in $vhost_pool ."
sed 's/{{SERVER_NAME}}/'"${SERVER_NAME}"'/' -i $vhost_pool


############################################################################
#	SSL key setup for nginx.                                           #
############################################################################

if [ "$HTTPS_ON" = "true" ]; then

  if [ ! -d $vhost_ssl_path ]; then
    echo "Creating directory $vhost_ssl_path ."
    mkdir -p $vhost_ssl_path
  fi
  
  # create the server private key
  if [ ! -e $ssl_key ]; then
    openssl req -x509 -newkey rsa:4096 -sha512 -batch -nodes -out $ssl_crt -keyout $ssl_key
    echo "Generating $ssl_key ."
    #openssl genrsa -out $ssl_key 4096
  fi
  
  #if [ ! -e $ssl_csr ]; then
  #  echo "Creating the CSR $ssl_csr ."
    #create the certificate signing request (CSR)
  #  openssl -req -new -key $ssl_key -out $ssl_csr
  #fi

  #if [ ! -e $ssl_crt ]; then
  #  echo "Creating the CRT $ssl_crt ."
  #  # sign the certificate using the private key and CSR
  #  openssl x509 -req days 365 -in $ssl_csr -signkey $ssl_key -out $ssl_crt
  #fi

  if [ ! -e $ssl_dhp ]; then
    echo "Creating diffie hellman parameter $ssl_dhp ."
    # generate stronger diffie hellman key exchange parameter
    openssl dhparam -out $ssl_dhp 2048
  fi

  echo "Setting chmod 400 to $ssl_key and chown www-data."
  chmod 400 $ssl_key
  chown www-data:www-data $ssl_key
fi


#############################################################################
#	Enable site with sym link to sites-enabled.                         #
#############################################################################
echo "Enabling site $vhost_config via sym link."
cp $vhost_config /etc/nginx/sites-enabled/$SERVER_NAME

