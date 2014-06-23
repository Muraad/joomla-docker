#!/bin/bash

#create a (ssl) setup
mkdir -p /etc/nginx/ssl/joomla

# create the server private key
openssl genrsa -out $SSL_KEY 2048

#create the certificate signing request (CSR)
openssl -req -new -key $SSL_KEY -out $SSL_CSR

# sign the certificate using the private key and CSR
openssl x509 -req days 365 -in $SSL_CSR -signkey $SSL_KEY -out $SSL_CRT

# generate stronger diffie hellman key exchange parameter
openssl dhparam -out $SSL_DHP 2048


