#!/usr/bin/env bash

apt update

if [ $(dpkg-query -W -f='${Status}' openjdk-8-jre-headless 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt install openjdk-8-jre-headless && Y
fi

MB_FOLDER=/opt/metabase

if [ ! -d "$MB_FOLDER" ]; then
  mkdir -p /opt/metabase && cd /opt/metabase
else
  echo "El directorio $MB_FOLDER ya existe"
fi

MB_FILE=/opt/metabase/metabase.jar

if [ ! -f "$MB_FILE" ]; then
  wget https://downloads.metabase.com/v0.37.8/metabase.jar
else
  echo "El archivo $MB_FILE ya existe"
fi

echo "Proceso finalizado"
