#!/bin/bash

# using settings from http://docs.joomla.org/Security_Checklist/Hosting_and_Server_Setup
# File permissions (like described for apache and fast-cgi


# Document root with public html 
chmod 750 ${1}/${2}/httpdocs

# all html to 644 (444 if paranoid)
chmod 644 $ (find -path *.html -type f ${1}/${2}/httpdocs)

# all images to 644 (444 if paranoid)
chmod 644 ${1}/${2}/httpdocs/images

# all php files to 600 (400 if paranoid)
chmod 600 $ (find -path *.php -type f ${1}/${2}/httpdocs/)
