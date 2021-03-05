#!/usr/bin/env bash

# Metabase Boilerplate. Copyright (c) 2021, https://www.kemok.io

set -o errexit
set -o nounset
set -o pipefail

echo "Proceso de instalación de Metabase y dependencias. Ingresa las siguientes variables:"

read -p "Host de la base de datos [default=127.0.0.1]: " MB_DB_HOST
MB_DB_HOST=${MB_DB_HOST:-127.0.0.1}

read -p "Puerto de la base de datos [default=5432]: " MB_DB_PORT
MB_DB_PORT=${MB_DB_PORT:-5432}

read -p "Nombre de la base de datos [default=metabase]: " MB_DB_DBNAME
MB_DB_DBNAME=${MB_DB_DBNAME:-metabase}

read -p "Usuario de la base de datos [default=metabase_user]: " MB_DB_USER
MB_DB_USER=${MB_DB_USER:-metabase_user}

MB_DB_PASS=$(openssl rand -base64 24)

MB_ENCRYPTION_SECRET_KEY=$(openssl rand -base64 24)


read -p "¿Todos los datos son correctos? (S/s) " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Ss]$ ]]
then

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

# Check if Nginx is already installed.
if [ $(dpkg-query -W -f='${Status}' nginx 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt install nginx -y
fi

# Check if postgreSQL is already installed.
if [ $(dpkg-query -W -f='${Status}' postgresql-11 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  apt update -y
  apt install postgresql-11 -y
fi

# Creating DB and USERDB
sudo -i -u postgres <<EOF
psql -c "drop database if exists $MB_DB_DBNAME"
psql -c "drop user if exists $MB_DB_USER"
psql -c "CREATE USER $MB_DB_USER WITH PASSWORD '$MB_DB_PASS';"
createdb testiedb
psql -c "GRANT ALL PRIVILEGES ON DATABASE $MB_DB_DBNAME TO $MB_DB_USER;"
exit
EOF

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

# Create an unprivileged user to run Metabase and give him acces to app and logs
groupadd -r metabase
useradd -r -s /bin/false -g metabase metabase
chown -R metabase:metabase $MB_FOLDER
touch /var/log/metabase.log
chown metabase:metabase /var/log/metabase.log
touch /etc/default/metabase
chmod 640 /etc/default/metabase

# Creating Metabase service file
touch /etc/systemd/system/metabase.service

echo "[Unit]
Description=Metabase server
After=syslog.target
After=network.target
   
[Service]
WorkingDirectory=MB_FOLDER
ExecStart=/usr/bin/java -jar MB_FILE
EnvironmentFile=/etc/default/metabase
User=metabase
Type=simple
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=metabase
SuccessExitStatus=143
TimeoutStopSec=120
Restart=always
   
[Install]
WantedBy=multi-user.target" | tee /etc/systemd/system/metabase.service

# Creating syslog conf
touch /etc/rsyslog.d/metabase.conf

echo "if $programname == 'metabase' then /var/log/metabase.log & stop" | tee /etc/rsyslog.d/metabase.conf
systemctl restart rsyslog.service

# Writing on Metabase config file
echo "MB_JETTY_HOST=0.0.0.0
MB_JETTY_PORT=3000
MB_DB_TYPE=postgres
MB_DB_DBNAME=$MB_DB_DBNAME
MB_DB_HOST=$MB_DB_HOST
MB_DB_PORT=$MB_DB_PORT
MB_DB_USER=$MB_DB_USER
MB_DB_PASS=$MB_DB_PASS
MB_ENCRYPTION_SECRET_KEY=$MB_ENCRYPTION_SECRET_KEY" | tee /etc/default/metabase

#Nginx configuration

else

    exit 0
    
fi




