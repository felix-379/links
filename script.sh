#!/usr/bin/env bash

apt update

apt install openjdk-8-jre-headless && y

mkdir -p /opt/metabase && cd /opt/metabase

wget https://downloads.metabase.com/v0.37.8/metabase.jar

echo "Proceso finalizado"
