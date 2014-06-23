joomla-docker
=============

Docker container for Joomla running under Nginx, Php-Fpm and MariaDb. 

More docs comming soon.

## Info

The containers ENTRYPOINT is the setup.sh script.

The following `VOLUME´s` are exposed by the container.

    VOLUME ["/var/mysql"]
    VOLUME ["/var/www"]
    VOLUME ["/var/www/vhosts"]
    VOLUME ["/etc/nginx/sites-available"]
    VOLUME ["/etc/nginx/ssl"]
    VOLUME ["/etc/php5/fpm/pool.d"]

And `Port` 22, 80 and 443 are exposed.

## Running the container

    docker run -d -p 80:80 -p 443:443 -e "SERVER_NAME=example.com" joomla/nginx setup-joomla
  
This will start the container with a fresh joomla (3.3.1) version that is available under SERVER_NAME.


## Run the container in debug mode

    docker run -i -t joomla/nginx debug
  
This will give you a root bash to play with.

```
  [ root@90dcbd3c55d4:/etc/nginx ]$
```

Now the setup script could be called manually. It resides in /tmp

    [ root@90dcbd3c55d4:/etc/nginx ]$ ./tmp/setup.sh setup-joomla

## Taking backups

Suppose a joomla/nginx container was started and is maybe still running.
First get the name of the running joomla/nginx container.

    sudo docker ps
  
    CONTAINER ID        IMAGE                 COMMAND                CREATED              STATUS              PORTS                                              NAMES
    72f38349cd33        joomla/nginx:latest   /tmp/setup.sh setup-   About a minute ago   Up About a minute   22/tcp,   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   clever_goodall

Here the container name is `clever_goodall`.

To take a backup of the data inside this container the shortest is to use the `backup-joomla.sh`.

    ./backup-joomla.sh clever_goodall

The script is calling

    docker run --volumes-from $1 -v $(pwd):/backup joomla/nginx backup
    
where `$1` is `clever_goodall`. 

This can be called instead of the `backup-joomla.sh`

This will backup all data and tar all data from:

  - /var/mysql
  - /var/www/vhosts
  - /etc/nginx/ssl
  - /etc/nginx/sites-available
  - /etc/php5/fpm/pool.d

The tar files are stored in a new directory `backup`.

For example:

    ./backup-joomla.sh clever_goodall
    Creating a backup...
    Creating mysql-backup.tar
    tar: Removing leading `/' from member names
    Creating vhosts-www-backup.tar
    tar: Removing leading `/' from member names
    Creating ssl-bakup.tar
    tar: Removing leading `/' from member names
    Creating sites-available-backup.tar
    tar: Removing leading `/' from member names
    Creating fpm-pool.tar
    tar: Removing leading `/' from member names


     ls -l backup/
      total 61088
      -rw-r--r-- 1 root root    20480 Jun 23 15:30 fpm-pool-backup.tar
      -rw-r--r-- 1 root root 30464000 Jun 23 15:30 mysql-backup.tar
      -rw-r--r-- 1 root root    10240 Jun 23 15:30 sites-available-backup.tar
      -rw-r--r-- 1 root root    10240 Jun 23 15:30 ssl-backup.tar
      -rw-r--r-- 1 root root 32040960 Jun 23 15:30 vhosts-www-backup.tar


## Restoring a container from a backup

To start a new container that is using the backup mount the `backup` folder 
as `/tmp/backup` and start the container without any `CMD` argument for then entry point.
The `setup.sh` will untar all files in `/tmp/backup` to the right place.

    docker run -d -p 80:80 -p 443:443 -v <backup_folder_path>:/tmp/backup joomla/nginx

Remeber `docker` wants an absolute path for `<backup_folder_path>`.

## SSH into container

By default there is a user `ssh-user` with password `ssh-user` 
that is allowed to `sudo` everything without the need to enter the password.

First get the container ip.

    docker inspect --format='{{.NetworkSettings.IPAddress}}' clever_goodall

Here it was 

    172.17.0.14

Then do 

    ssh ssh-user@172.17.0.14
    ...
    
## Additional information.

The `setup.sh` script that is called as `ENTRYPOINT` is checking if the following directorys are existing.
And if they are present gets copied to the right place.
So one can mount host data for a custom setup of the container.

    - /tmp/sites-available      -> /etc/nginx/sites-available/
    - /tmp/vhost                -> /var/www/vhosts/
    - /tmp/ssl                  -> /etc/nginx/ssl/
    - /tmp/mysql                -> /var/mysql/
    - /tmp/php-fpm-pools        -> /etc/php5/fpm/pool.d


