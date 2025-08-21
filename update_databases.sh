#!/bin/bash

# Define os nomes dos containers
MYSQL_CONTAINER="cdc-mysqldb-1"
POSTGRES_CONTAINER="cdc-postgresdb-1"

echo "Iniciando a inserção e atualização de dados variados..."

# --- Cenário 1: Histórico de um Produto (PostgreSQL) ---
echo "Gerando histórico de um produto no PostgreSQL..."
# Produto 1: 'Camisa branca tipo polo'
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 1ª Atualização de preço
UPDATE products SET price = 75, quantity = 4, status = 'in_stock' WHERE id = 1;
EOF
sleep 1 # Pausa para garantir que o timestamp seja diferente
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 2ª Atualização de status para 'running_low'
UPDATE products SET status = 'running_low', quantity = 2 WHERE id = 1;
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 3ª Nova atualização de preço
UPDATE products SET price = 72 WHERE id = 1;
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 4ª Atualização para 'out_of_stock'
UPDATE products SET status = 'out_of_stock', quantity = 0 WHERE id = 1;
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 5ª Reabastecendo o estoque e ajustando o preço
UPDATE products SET price = 70, quantity = 10, status = 'in_stock' WHERE id = 1;
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 6ª Promoção de preço
UPDATE products SET price = 45 WHERE id = 1;
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 7ª Outra atualização na quantidade
UPDATE products SET quantity = 8 WHERE id = 1;
EOF

# --- Cenário 2: Variação de Preços (PostgreSQL) ---
echo "Simulando variação de preços para outros produtos..."
# Produto 2: 'Bermuda preta sem bolso'
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 1ª Atualização
UPDATE products SET price = 35 WHERE id = 2;
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 2ª Atualização
UPDATE products SET price = 30 WHERE id = 2;
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 3ª Atualização
UPDATE products SET price = 28 WHERE id = 2;
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 4ª Atualização
UPDATE products SET price = 32 WHERE id = 2;
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 5ª Atualização
UPDATE products SET price = 29 WHERE id = 2;
EOF

# --- Cenário 3: Novo Produto e Variações (PostgreSQL) ---
echo "Adicionando e atualizando um novo produto..."
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 1ª Inserção
INSERT INTO products (name_description, price, quantity, status) VALUES ('Cinto de couro', 49, 10, 'in_stock');
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 2ª Atualização
UPDATE products SET price = 55, quantity = 8 WHERE name_description = 'Cinto de couro';
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 3ª Atualização de status e quantidade
UPDATE products SET quantity = 2, status = 'running_low' WHERE name_description = 'Cinto de couro';
EOF
sleep 1
docker exec -i $POSTGRES_CONTAINER psql -U postgres -d postgres <<EOF
-- 4ª Compra para estoque de cinto
UPDATE products SET quantity = 4, status = 'in_stock' WHERE name_description = 'Cinto de couro';
EOF

# --- Cenário 4: Histórico de um Usuário (MySQL) ---
echo "Gerando histórico de um usuário no MySQL..."
# Usuário 1: 'Indiana Jones'
docker exec -i $MYSQL_CONTAINER mysql -uadmin -padmin usuarios <<EOF
-- 1ª Atualização do nome e endereço
UPDATE users SET full_name='Indy Jones', address='Archaeology Street' WHERE id=1;
EOF
sleep 1
docker exec -i $MYSQL_CONTAINER mysql -uadmin -padmin usuarios <<EOF
-- 2ª Outra atualização no nome
UPDATE users SET full_name='Dr. Indy Jones' WHERE id=1;
EOF
sleep 1
docker exec -i $MYSQL_CONTAINER mysql -uadmin -padmin usuarios <<EOF
-- 3ª Atualização do nome e endereço completo
UPDATE users SET full_name='Dr. Indy Jones', address='Universidade de Chicago' WHERE id=1;
EOF
sleep 1
docker exec -i $MYSQL_CONTAINER mysql -uadmin -padmin usuarios <<EOF
-- 4ª Mudança de endereço
UPDATE users SET address='Egito' WHERE id=1;
EOF
sleep 1
docker exec -i $MYSQL_CONTAINER mysql -uadmin -padmin usuarios <<EOF
-- 5ª Mudança final de nome e endereço
UPDATE users SET full_name='Indiana Jones', address='Home Base' WHERE id=1;
EOF

# --- Cenário 5: Novo Usuário e Variações (MySQL) ---
echo "Adicionando e atualizando um novo usuário..."
docker exec -i $MYSQL_CONTAINER mysql -uadmin -padmin usuarios <<EOF
-- 1ª Inserção
INSERT INTO users (full_name, created_at, address) VALUES("Luke Skywalker", NOW(), "Millennium Falcon");
EOF
sleep 1
docker exec -i $MYSQL_CONTAINER mysql -uadmin -padmin usuarios <<EOF
-- 2ª Atualização de endereço
UPDATE users SET address='Em direcao ao resgate da Princesa Leia' WHERE full_name='Luke Skywalker';
EOF
sleep 1
docker exec -i $MYSQL_CONTAINER mysql -uadmin -padmin usuarios <<EOF
-- 3ª Mudança de endereço
UPDATE users SET address='Base Rebelde, Yavin 4' WHERE full_name='Luke Skywalker';
EOF
sleep 1
docker exec -i $MYSQL_CONTAINER mysql -uadmin -padmin usuarios <<EOF
-- 4ª Outra mudança de endereço
UPDATE users SET address='Nave Estrela da Morte' WHERE full_name='Luke Skywalker';
EOF
sleep 1
docker exec -i $MYSQL_CONTAINER mysql -uadmin -padmin usuarios <<EOF
-- 5ª Mudança de nome e endereço
UPDATE users SET full_name='Luke Jedi', address='Tatooine, planeta lar doce lar' WHERE full_name='Luke Skywalker';
EOF

echo "Todos os dados foram inseridos e atualizados. O pipeline CDC processará as mudanças. ✅"
