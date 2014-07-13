#!/bin/bash

# add new user too with username = $1 and password = $2
#if [ $# -eq 2 ]; then
  echo "Enter the database username for the new joomla user"
  read -p "Enter username for joomla mysql user: " user

  pw="empty"
  while true
  do
    read -p "Enter new user password: " tmp
    read -p "Enter new user password again: " tmp1
    echo "${tmp}:${tmp1}"
    if [ "$tmp" != "$tmp1" ]; then
      echo "Please try again!"
    else
      echo "Paswords match :)"
      pw=$tmp
      break
    fi
  done
  echo "PW is ${pw}"
