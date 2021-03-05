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
  read -s 
  MB_DB_PASS=$REPLY
  echo -n "Confirmar password: "
  read -s 
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
psql -c "drop database if exists testiedb"
psql -c "drop user if exists testie"
psql -c "CREATE USER testie WITH PASSWORD '123';"
createdb testiedb
psql -c "GRANT ALL PRIVILEGES ON DATABASE testiedb TO testie;"
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


else

    exit 0
    
fi




