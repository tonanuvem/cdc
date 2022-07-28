#!/bin/bash
bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:8073)" != "200" ]]; do echo .; sleep 5; done'
echo "Debezium CDC is up"

#HOST_IP=$(curl checkip.amazonaws.com)
#echo $HOST_IP

echo "Configurando CDC para Postgres:"
curl -s -X POST http://localhost:8073/connectors \
  -H "accept: */*" -H "Content-Type: application/json" \
  -d @connectors_config/postgres.json \
  | python -mjson.tool

echo "Configurando CDC para MySQL"
curl -s -X POST http://localhost:8073/connectors \
  -H "accept: */*" -H "Content-Type: application/json" \
  -d @connectors_config/mysql.json \
  | python -mjson.tool
