FROM dockerfile/nginx

###########################################################################
#	                                                                  #
#	Environment variable defaults for                                 #
#	- the www data directory                                          #
#	- the mysql data directory                                        #
#	- the path to store the ssl keys, csr´s and diffie hellman params.#
#	- the joomla version that is downloaded/used.                     #
#	                                                                  #
###########################################################################

ENV WWW_DIR /var/www/vhosts
ENV MYSQL_DATA /var/mysql
ENV JOOMLA_VERSION 3.3.1
ENV SERVER_NAME example.com

###########################################################################
#	php5, openssh-server, supervisord and mariaDb installation        #
###########################################################################
RUN add-apt-repository -y ppa:ondrej/php5; apt-get -y --force-yes update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes -q\
  openssh-server openssl supervisor mariadb-server\
  cron\
  php5-fpm php5 php5-cli php5-dev php-pear php5-common php5-apcu\
  php5-mcrypt php5-gd php5-mysql php5-curl php5-json\
  memcached php5-memcached\
  php5-imagick
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes php-apc
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y --force-yes



###########################################################################
#	Download the latest joomla version.                               #
###########################################################################
RUN wget http://joomlacode.org/gf/download/frsrelease/19524/159412/Joomla_${JOOMLA_VERSION}-Stable-Full_Package.tar.bz2


###########################################################################
#	Install and config memcache                                       #
###########################################################################
RUN pecl install memcache;
ADD conf/memcache.ini /etc/php5/mods-available/memcache.ini
RUN /usr/sbin/php5enmod memcache

##########################################################################
# 	                                                                 #
# 	ADD configuration files.                                         #
#	- vhost php-fpm pool config template  -> 	/tmp/            #
#	- php.ini			/etc/php5/fpm/                   #
#	- php-fpm.ini			/etc/php5/fpm/                   #    
#	- nginx.conf			/etc/nginx/                      #
#	- fastcgi_params		/etc/nginx/                      #
#	- joomla.config			/tmp/                            #
#	- sites-availabe directory	/etc/nginx/sites-available       #
#	- vhosts directory 		/var/www/vhosts/                 #
##########################################################################

ADD conf/php.ini /etc/php5/fpm/php.ini

# Remove default php-fpm pool
RUN rm -rf /etc/php5/fpm/pool.d/*

# Add vhost config template
ADD conf/www.conf.template /tmp/www.conf.template

# nginx
ADD conf/nginx.conf /etc/nginx/nginx.conf

# fast cgi parameter
#ADD conf/fastcgi_params /etc/nginx/fastcgi_params

ADD conf/joomla.conf /etc/nginx/conf/joomla.conf

# joomla nginx vhost, will include joomla.conf
ADD conf/joomla.vhost.template /tmp/joomla.vhost.template
ADD conf/joomla.vhost.http.template /tmp/joomla.vhost.http.template

# supervisord config, is supervising php5-fpm, nginx and mariaDb
ADD conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf


###########################################################################
#                                                                         #
#	ADD scripts:							  #
#	- setup.sh			-> 	/tmp/			  #
#	- init-mysql.sh			->	/tmp/			  #
#	- secure-joomla.sh		->	/tmp/			  #
#	- conf/setup-joomla-vhost.sh	->	/tmp/                     #
#	and makes them executable.					  #
#	                                                                  #
###########################################################################

# After container is started, this script should be called
# via ssh from host to set the root password(s).
# it will also set mysql_history to /dev/null
ADD init-mysql.sh /tmp/init-mysql.sh

# add secure-joomla.sh script to harden permissions after web installation
ADD secure-joomla.sh /tmp/secure-joomla.sh

# It will setup the vhosts via given SERVER_NAME environment variable.
ADD conf/setup-joomla-vhost.sh /tmp/setup-joomla-vhost.sh

#########################################################################
#	Volumes                                                          #
#	- mysql data                                                     #
#	- www data                                                       #
#       - vhosts www data                                                #
#	- vhost configs in sites-available                               #
#	- vhost php-fpm pool configurations                              #
#	for taking backups                                               #
##########################################################################
VOLUME ["/var/mysql"]
VOLUME ["/var/www"]
VOLUME ["/var/www/vhosts"]
VOLUME ["/etc/nginx/sites-available"]
VOLUME ["/etc/nginx/ssl"]
VOLUME ["/etc/php5/fpm/pool.d"]

# Add setup script.
ADD setup.sh /tmp/setup.sh 
# Make it executable for root
RUN chmod u+rx /tmp/setup.sh;

EXPOSE 22 443

ENTRYPOINT ["/tmp/setup.sh"]
