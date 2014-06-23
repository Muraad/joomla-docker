#!/bin/sh

# $1 - The container name (joomla/nginx) where to take the backups from
sudo docker run --volumes-from $1 -v $(pwd):/backup joomla2/nginx backup
