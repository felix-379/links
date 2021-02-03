#!/usr/bin/env bash

echo "Ingresa las siguientes variables"

echo -n "Nombre de la base de datos: "
read -r 
MB_DB_DBNAME=$REPLY

echo -n "Puerto de la base de datos: "
read -r 
MB_DB_PORT=$REPLY

echo -n "Usuario de la base de datos: "
read -r 
MB_DB_USER=$REPLY

while true; do
  echo -n "Password de la base de datos: "
  read -s -p 
  MB_DB_PASS=$REPLY
  echo -n "Confirmar password: "
  read -s -p 
  MB_DB_PASS_CONFIRM=$REPLY
   echo
    [ "$MB_DB_PASS" = "$MB_DB_PASS_CONFIRM" ] && break
    echo "Password no coincide"
done

echo -n "Host de la base de datos: "
read -r 
MB_DB_HOST=$REPLY

MB_ENCRYPTION_SECRET_KEY=$(openssl rand -base64 24)


read -p "¿Todos los datos son correctos? (S/s) " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Ss]$ ]]

apt update -y

# Check if JRE is already installed.
if [ $(dpkg-query -W -f='${Status}' openjdk-8-jre-headless 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt install openjdk-8-jre-headless -y
fi

# Check if Certbot is already installed.
if [ $(dpkg-query -W -f='${Status}' certbot 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt install certbot -y
fi

# Check if postgreSQL is already installed.
if [ $(dpkg-query -W -f='${Status}' postgresql-11 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  apt update -y
  apt install postgresql-11 -y
fi

# Check if MB directory and file app already exists.
MB_FOLDER=/opt/metabase
MB_FILE=/opt/metabase/metabase.jar

if [ ! -d "$MB_FOLDER" ]; then
  mkdir -p /opt/metabase && cd /opt/metabase
else
  echo "El directorio $MB_FOLDER ya existe"
fi

if [ ! -f "$MB_FILE" ]; then
  wget https://downloads.metabase.com/v0.37.8/metabase.jar
else
  echo "El archivo $MB_FILE ya existe"
fi

echo "Proceso finalizado"

else

    exit 1
    
fi




