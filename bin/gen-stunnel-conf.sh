#!/usr/bin/env bash

n=1

mkdir -p /app/vendor/stunnel/var/run/stunnel/
echo "$STUNNEL_PEM" > /app/vendor/stunnel/stunnel.pem
cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF
foreground = yes
cert=/app/vendor/stunnel/stunnel.pem
key=/app/vendor/stunnel/stunnel.pem
options = NO_SSLv2
options = SINGLE_ECDH_USE
options = SINGLE_DH_USE
socket = r:TCP_NODELAY=1
options = NO_SSLv3
ciphers = HIGH:!ADH:!AECDH:!LOW:!EXP:!MD5:!3DES:!SRP:!PSK:@STRENGTH
EOFEOF

for STUNNEL_URL in $STUNNEL_URLS
do
  eval STUNNEL_URL_VALUE=\$$STUNNEL_URL
  #TODO: Generalize away that "redis" bit in the next line
  url=$(echo $STUNNEL_URL_VALUE | perl -lne 'print "$1 $2 $3 $4" if /^(.*?)([^\/]+):([0-9]+)(.*)$/')
  url=( $url )
  prefix=${url[0]}
  host=${url[1]}
  port=${url[2]}
  suffix=${url[3]}
  
  echo "Setting ${STUNNEL_URL}_STUNNEL config var"
  client_port="600${n}"
  
  export ${STUNNEL_URL}_STUNNEL="${prefix}localhost:${client_port}${suffix}"

  cat >> /app/vendor/stunnel/stunnel.conf << EOFEOF
[$STUNNEL_URL]
client = yes
accept = ${client_port}
connect = ${host}:${port}
EOFEOF

  let "n += 1"
done

chmod go-rwx /app/vendor/stunnel/*
