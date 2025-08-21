#!/bin/bash

# Define os nomes dos containers
MYSQL_CONTAINER="cdc-mysqldb-1"
POSTGRES_CONTAINER="cdc-postgresdb-1"

echo "Iniciando a inserção e atualização de dados variados..."

# --- Cenário 1: Histórico de um Produto (PostgreSQL) ---
echo "Gerando histórico de um produto no PostgreSQL..."
# Produto 1: 'Camisa branca tipo polo'
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- Atualização de preço
UPDATE products SET price = 75, quantity = 4, status = 'in_stock' WHERE id = 1;
EOF
sleep 1 # Pausa para garantir que o timestamp seja diferente
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- Atualização de status para 'running_low'
UPDATE products SET status = 'running_low', quantity = 2 WHERE id = 1;
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- Nova atualização de preço
UPDATE products SET price = 72 WHERE id = 1;
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- Atualização para 'out_of_stock'
UPDATE products SET status = 'out_of_stock', quantity = 0 WHERE id = 1;
EOF

# --- Cenário 2: Variação de Preços (PostgreSQL) ---
echo "Simulando variação de preços para outros produtos..."
# Produto 2: 'Bermuda preta sem bolso'
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
UPDATE products SET price = 35 WHERE id = 2;
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
UPDATE products SET price = 30 WHERE id = 2;
EOF

# --- Cenário 3: Novo Produto e Variações (PostgreSQL) ---
echo "Adicionando e atualizando um novo produto..."
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
INSERT INTO products (name_description, price, quantity, status) VALUES ('Cinto de couro', 49, 10, 'in_stock');
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
UPDATE products SET price = 55, quantity = 8 WHERE name_description = 'Cinto de couro';
EOF

# --- Cenário 4: Histórico de um Usuário (MySQL) ---
echo "Gerando histórico de um usuário no MySQL..."
# Usuário 1: 'Indiana Jones'
docker exec -i $MYSQL_CONTAINER mysql -uadmin -padmin usuarios <<EOF
-- Atualização do nome e endereço
UPDATE users SET full_name='Indy Jones', address='Archaeology Street' WHERE id=1;
EOF
sleep 1
docker exec -i $MYSQL_CONTAINER mysql -uadmin -padmin usuarios <<EOF
-- Outra atualização
UPDATE users SET full_name='Dr. Henry Jones Jr.' WHERE id=1;
EOF

# --- Cenário 5: Novo Usuário e Variações (MySQL) ---
echo "Adicionando e atualizando um novo usuário..."
docker exec -i $MYSQL_CONTAINER mysql -uadmin -padmin usuarios <<EOF
INSERT INTO users (full_name, created_at, address) VALUES("Luke Skywalker", NOW(), "Tatooine");
EOF
sleep 1
docker exec -i $MYSQL_CONTAINER mysql -uadmin -padmin usuarios <<EOF
UPDATE users SET address='Coruscant' WHERE full_name='Luke Skywalker';
EOF

echo "Todos os dados foram inseridos e atualizados. O pipeline CDC processará as mudanças. ✅"
