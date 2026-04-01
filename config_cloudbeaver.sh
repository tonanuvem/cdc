#!/bin/bash

# Aguardar CloudBeaver iniciar
echo "Aguardando CloudBeaver inicializar..."
sleep 15

# Fazer login como admin
SESSION=$(curl -s -X POST http://localhost:8978/api/gql \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { authLogin(provider: \"local\", credentials: {user: \"admin\", password: \"admin\"}) { authId } }"}' | jq -r '.data.authLogin.authId')

echo "Session ID: $SESSION"

# Criar conexão PostgreSQL
curl -s -X POST http://localhost:8978/api/gql \
  -H "Content-Type: application/json" \
  -H "Cookie: cb-session-id=$SESSION" \
  -d '{
    "query": "mutation { createConnection(config: {name: \"Postgres - Produtos\", driverId: \"postgresql:postgres-jdbc\", host: \"postgresdb\", port: \"5432\", databaseName: \"postgres\", credentials: {userName: \"postgres\", userPassword: \"admin\"}, saveCredentials: true}) { id } }"
  }'

echo ""

# Criar conexão MySQL
curl -s -X POST http://localhost:8978/api/gql \
  -H "Content-Type: application/json" \
  -H "Cookie: cb-session-id=$SESSION" \
  -d '{
    "query": "mutation { createConnection(config: {name: \"MySQL - Usuários\", driverId: \"mysql:mysql8\", host: \"mysqldb\", port: \"3306\", databaseName: \"usuarios\", credentials: {userName: \"admin\", userPassword: \"admin\"}, saveCredentials: true}) { id } }"
  }'

echo ""
echo "Conexões criadas!"
