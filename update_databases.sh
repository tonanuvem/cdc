#!/bin/bash

# Script para inserção de dados em lote para demonstracao dos relatorios
# Adiciona 17 produtos + 17 usuarios e faz ~20 alteracoes em cada um

set -e

# Configuracao dos conteineres
CONTEINER_POSTGRES="cdc-postgresdb-1"
CONTEINER_MYSQL="cdc-mysqldb-1"

# Configuracao das tabelas
TABELA_PRODUTOS="products"
TABELA_USUARIOS="users"
DATABASE_MYSQL="usuarios"

echo "🚀 Iniciando insercao de dados em lote para demonstracao de relatorios..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funcao para logging
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}"
}

# --- Estrutura dos bancos de dados (apenas para referencia) ---

: '
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE TYPE "products_status" AS ENUM (
    "out_of_stock",
    "in_stock",
    "running_low"
  );
  CREATE TABLE "products" (
    "id" SERIAL PRIMARY KEY,
    "name_description" varchar,
    "price" int,
    "quantity" int,
    "status" products_status,
    "created_at" TIMESTAMPTZ DEFAULT Now(),
    "updated_at" TIMESTAMPTZ DEFAULT Now()
  );
  CREATE INDEX "product_status" ON "products" ("status");
  CREATE UNIQUE INDEX ON "products" ("id");
  
  INSERT INTO products (name_description,price,quantity,status) VALUES ('Camisa branca tipo polo', 69, 5, 'in_stock');
  INSERT INTO products (name_description,price,quantity,status) VALUES ('Bermuda preta sem bolso', 29, 5, 'in_stock');
  INSERT INTO products (name_description,price,quantity,status) VALUES ('Meia preta do tipo social', 19, 5, 'in_stock');  
EOSQL

USE usuarios;

CREATE TABLE `users` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `full_name` varchar(255),
  `created_at` timestamp,
  `updated_at` timestamp,
  `address` varchar(255)
);

SET character_set_client = utf8;
SET character_set_connection = utf8;
SET character_set_results = utf8;
SET collation_connection = utf8_general_ci;

INSERT INTO users (full_name,created_at, address) VALUES("Indiana Jones",NOW(),"Adventures Avenue");
INSERT INTO users (full_name,created_at, address) VALUES("Jack Sparrow",NOW(),"Master Ship Square");
INSERT INTO users (full_name,created_at, address) VALUES("John Snow",NOW(),"Kinds Landing Westeros");
'

# --- Funcoes do script ---

# Verificar se os containers estao rodando
check_containers() {
    log "Verificando se os containers estao rodando..."
    
    if ! docker ps | grep -q $CONTEINER_POSTGRES; then
        error "Container $CONTEINER_POSTGRES nao esta rodando!"
        exit 1
    fi
    
    if ! docker ps | grep -q $CONTEINER_MYSQL; then
        error "Container $CONTEINER_MYSQL nao esta rodando!"
        exit 1
    fi
    
    log "✅ Todos os containers estao rodando"
}

# Funcao para executar SQL no PostgreSQL
exec_postgres() {
    docker exec -i $CONTEINER_POSTGRES psql -U postgres -d postgres -c "$1"
}

# Funcao para executar SQL no MySQL
exec_mysql() {
    docker exec -i $CONTEINER_MYSQL mysql -u admin -padmin $DATABASE_MYSQL -e "$1"
}

# Verificar dados existentes
check_existing_data() {
    log "Verificando dados existentes..."
    
    EXISTING_PRODUCTS=$(docker exec -i $CONTEINER_POSTGRES psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM $TABELA_PRODUTOS;" | tr -d ' ' | head -n 1)
    EXISTING_USERS=$(docker exec -i $CONTEINER_MYSQL mysql -u admin -padmin $DATABASE_MYSQL -N -e "SELECT COUNT(*) FROM $TABELA_USUARIOS;" 2>/dev/null | tr -d ' ' | head -n 1)
    
    # Verificar se os valores sao numeros validos
    if ! [[ "$EXISTING_PRODUCTS" =~ ^[0-9]+$ ]]; then
        EXISTING_PRODUCTS=0
    fi
    
    if ! [[ "$EXISTING_USERS" =~ ^[0-9]+$ ]]; then
        EXISTING_USERS=0
    fi
    
    info "Produtos existentes: $EXISTING_PRODUCTS"
    info "Usuarios existentes: $EXISTING_USERS"
    
    if [ "$EXISTING_PRODUCTS" -lt 3 ] || [ "$EXISTING_USERS" -lt 3 ]; then
        warn "Menos de 3 produtos/usuarios existentes. Continuando mesmo assim..."
    fi
}

# Inserir 17 novos produtos
add_17_products() {
    log "Adicionando 17 novos produtos..."
    
    exec_postgres "
    INSERT INTO $TABELA_PRODUTOS (name_description, price, quantity, status, created_at) VALUES 
    ('Camiseta basica branca', 35.90, 25, 'in_stock', NOW() - INTERVAL '60 days'),
    ('Calca jeans slim azul', 89.90, 12, 'in_stock', NOW() - INTERVAL '58 days'),
    ('Tenis casual branco', 199.00, 8, 'in_stock', NOW() - INTERVAL '56 days'),
    ('Jaqueta bomber preta', 149.90, 6, 'in_stock', NOW() - INTERVAL '54 days'),
    ('Shorts jeans desbotado', 59.90, 15, 'in_stock', NOW() - INTERVAL '52 days'),
    ('Sapato social preto', 179.90, 4, 'running_low', NOW() - INTERVAL '50 days'),
    ('Bone snapback azul', 45.90, 20, 'in_stock', NOW() - INTERVAL '48 days'),
    ('Moletom capuz cinza', 89.90, 10, 'in_stock', NOW() - INTERVAL '46 days'),
    ('Regata fitness preta', 29.90, 30, 'in_stock', NOW() - INTERVAL '44 days'),
    ('Calca moletom jogger', 69.90, 8, 'in_stock', NOW() - INTERVAL '42 days'),
    ('Chinelo slide preto', 39.90, 50, 'in_stock', NOW() - INTERVAL '40 days'),
    ('Camisa social branca', 99.90, 7, 'in_stock', NOW() - INTERVAL '38 days'),
    ('Bermuda tactel verde', 49.90, 18, 'in_stock', NOW() - INTERVAL '36 days'),
    ('Tenis running vermelho', 249.90, 5, 'running_low', NOW() - INTERVAL '34 days'),
    ('Blusa tricot bege', 79.90, 12, 'in_stock', NOW() - INTERVAL '32 days'),
    ('Calca cargo marrom', 109.90, 6, 'in_stock', NOW() - INTERVAL '30 days'),
    ('Sandalia couro marrom', 129.90, 9, 'in_stock', NOW() - INTERVAL '28 days');
    "
    
    log "✅ 17 novos produtos adicionados"
}

# Inserir 17 novos usuarios
add_17_users() {
    log "Adicionando 17 novos usuarios..."
    
    exec_mysql "
    INSERT INTO $TABELA_USUARIOS (full_name, address, created_at) VALUES 
    ('Homem de Ferro', 'Torre Stark', DATE_SUB(NOW(), INTERVAL 60 DAY)),
    ('Capitao America', 'Quartel dos Vingadores', DATE_SUB(NOW(), INTERVAL 58 DAY)),
    ('Viuva Negra', 'Sede da SHIELD', DATE_SUB(NOW(), INTERVAL 56 DAY)),
    ('Hulk', 'Laboratorios de Pesquisa', DATE_SUB(NOW(), INTERVAL 54 DAY)),
    ('Thor', 'Reino de Asgard', DATE_SUB(NOW(), INTERVAL 52 DAY)),
    ('Loki', 'Prisao de Asgard', DATE_SUB(NOW(), INTERVAL 50 DAY)),
    ('Doutor Estranho', 'Sanctum Sanctorum', DATE_SUB(NOW(), INTERVAL 48 DAY)),
    ('Pantera Negra', 'Palacio de Wakanda', DATE_SUB(NOW(), INTERVAL 46 DAY)),
    ('Homem-Aranha', 'Apartamento em Queens', DATE_SUB(NOW(), INTERVAL 44 DAY)),
    ('Flash', 'Laboratorios S.T.A.R.', DATE_SUB(NOW(), INTERVAL 42 DAY)),
    ('Batman', 'Manao Wayne', DATE_SUB(NOW(), INTERVAL 40 DAY)),
    ('Superman', 'Planeta Diario', DATE_SUB(NOW(), INTERVAL 38 DAY)),
    ('Mulher-Maravilha', 'Themyscira', DATE_SUB(NOW(), INTERVAL 36 DAY)),
    ('Aquaman', 'Reino da Atlantida', DATE_SUB(NOW(), INTERVAL 34 DAY)),
    ('Arlequina', 'Esquadrao Suicida', DATE_SUB(NOW(), INTERVAL 32 DAY)),
    ('Coringa', 'Asilo Arkham', DATE_SUB(NOW(), INTERVAL 30 DAY)),
    ('Groot', 'Guardioes da Galaxia', DATE_SUB(NOW(), INTERVAL 28 DAY));
    "
    
    log "✅ 17 novos usuarios adicionados"
}

# Fazer ~20 alteracoes em produtos (distribuido ao longo do tempo)
simulate_product_updates() {
    log "Simulando ~20 alteracoes por produto ao longo do tempo..."
    
    # Get all product IDs
    PRODUCT_IDS=$(docker exec -i $CONTEINER_POSTGRES psql -U postgres -d postgres -t -c "SELECT id FROM $TABELA_PRODUTOS ORDER BY id;" | tr -d ' ')
    
    for product_id in $PRODUCT_IDS; do
        if [ -z "$product_id" ]; then
            continue
        fi
        
        info "Criando historico para produto ID: $product_id"
        
        # 20 alteracoes por produto distribuidas em 60 dias
        for i in {1..20}; do
            # Variacao aleatoria de preco (-20% a +30%)
            PRICE_VARIATION=$(shuf -i 80-130 -n 1)  # 80% a 130% do preco atual
            
            # Variacao de quantidade (1 a 50)
            QTY_VARIATION=$(shuf -i 1-50 -n 1)
            
            # Status baseado na quantidade
            if [ "$QTY_VARIATION" -le 3 ]; then
                STATUS="'running_low'"
            elif [ "$QTY_VARIATION" -eq 0 ]; then
                STATUS="'out_of_stock'"
            else
                STATUS="'in_stock'"
            fi
            
            # Dias atras para esta alteracao
            DAYS_AGO=$((60 - i * 3))
            if [ "$DAYS_AGO" -lt 0 ]; then
                DAYS_AGO=0
            fi
            
            exec_postgres "
            UPDATE $TABELA_PRODUTOS SET 
                price = ROUND((price * $PRICE_VARIATION / 100)::numeric, 2),
                quantity = $QTY_VARIATION,
                status = $STATUS,
                updated_at = NOW() - INTERVAL '$DAYS_AGO days'
            WHERE id = $product_id;
            " > /dev/null 2>&1
            
            # Sleep para nao sobrecarregar
            sleep 0.1
        done
    done
    
    log "✅ Simulacao de alteracoes de produtos concluida"
}

# Fazer ~20 alteracoes em usuarios
simulate_user_updates() {
    log "Simulando ~20 alteracoes por usuario ao longo do tempo..."
    
    # Arrays de variacoes para nomes e enderecos
    declare -a NAME_PREFIXES=("Dr." "Prof." "Sr." "Sra." "Mr." "Ms." "")
    declare -a NAME_SUFFIXES=("Jr." "Sr." "II" "III" "PhD" "MD" "")
    declare -a STREET_TYPES=("Street" "Avenue" "Boulevard" "Road" "Lane" "Drive" "Way")
    declare -a CITIES=("NYC" "LA" "Chicago" "Miami" "Boston" "Seattle" "Denver")
    
    # Get all user IDs
    USER_IDS=$(docker exec -i $CONTEINER_MYSQL mysql -u admin -padmin $DATABASE_MYSQL -N -e "SELECT id FROM $TABELA_USUARIOS ORDER BY id;" 2>/dev/null | tr -d ' ')
    
    for user_id in $USER_IDS; do
        if [ -z "$user_id" ]; then
            continue
        fi
        
        info "Criando historico para usuario ID: $user_id"
        
        # Get current user data
        CURRENT_USER=$(docker exec -i $CONTEINER_MYSQL mysql -u admin -padmin $DATABASE_MYSQL -N -e "SELECT full_name FROM $TABELA_USUARIOS WHERE id = $user_id;" 2>/dev/null)
        BASE_NAME=$(echo "$CURRENT_USER" | sed 's/Dr\.\|Prof\.\|Sr\.\|Sra\.\|Mr\.\|Ms\.\|Jr\.\|Sr\.\|II\|III\|PhD\|MD//g' | xargs)
        
        # 20 alteracoes por usuario
        for i in {1..20}; do
            # Variacao no nome (adicionar/remover prefixos/sufixos)
            PREFIX=${NAME_PREFIXES[$RANDOM % ${#NAME_PREFIXES[@]}]}
            SUFFIX=${NAME_SUFFIXES[$RANDOM % ${#NAME_SUFFIXES[@]}]}
            
            if [ $((i % 5)) -eq 0 ] && [ -n "$PREFIX" ]; then
                NEW_NAME="$PREFIX $BASE_NAME"
            elif [ $((i % 7)) -eq 0 ] && [ -n "$SUFFIX" ]; then
                NEW_NAME="$BASE_NAME $SUFFIX"
            elif [ $((i % 10)) -eq 0 ] && [ -n "$PREFIX" ] && [ -n "$SUFFIX" ]; then
                NEW_NAME="$PREFIX $BASE_NAME $SUFFIX"
            else
                NEW_NAME="$BASE_NAME"
            fi
            
            # Variacao no endereco
            STREET_NUM=$((RANDOM % 9999 + 1))
            STREET_NAME="Building $((RANDOM % 100 + 1))"
            STREET_TYPE=${STREET_TYPES[$RANDOM % ${#STREET_TYPES[@]}]}
            CITY=${CITIES[$RANDOM % ${#CITIES[@]}]}
            NEW_ADDRESS="$STREET_NUM $STREET_NAME $STREET_TYPE $CITY"
            
            # Dias atras para esta alteracao
            DAYS_AGO=$((60 - i * 3))
            if [ "$DAYS_AGO" -lt 0 ]; then
                DAYS_AGO=0
            fi
            
            exec_mysql "
            UPDATE $TABELA_USUARIOS SET 
                full_name = '$NEW_NAME',
                address = '$NEW_ADDRESS',
                updated_at = DATE_SUB(NOW(), INTERVAL $DAYS_AGO DAY)
            WHERE id = $user_id;
            " > /dev/null 2>&1
            
            # Sleep para nao sobrecarregar
            sleep 0.1
        done
    done
    
    log "✅ Simulacao de alteracoes de usuarios concluida"
}

# Criar padroes interessantes para analise
create_analysis_patterns() {
    log "Criando padroes interessantes para analise..."
    
    # Produto sazonal: aumentar precos de alguns produtos especificos
    info "🌞 Criando padrao sazonal - produtos de verao"
    exec_postgres "
    UPDATE $TABELA_PRODUTOS SET 
        price = price * 1.25,
        updated_at = NOW() - INTERVAL '5 days'
    WHERE name_description LIKE '%shorts%' 
        OR name_description LIKE '%regata%' 
        OR name_description LIKE '%chinelo%';
    "
    
    # Black Friday: grandes descontos
    info "🛍️ Criando padrao Black Friday - descontos massivos"
    exec_postgres "
    UPDATE $TABELA_PRODUTOS SET 
        price = price * 0.60,
        quantity = quantity + 20,
        updated_at = NOW() - INTERVAL '10 days'
    WHERE id IN (SELECT id FROM $TABELA_PRODUTOS ORDER BY RANDOM() LIMIT 8);
    "
    
    # Fim de estoque gradual
    info "📉 Criando padrao de fim de estoque"
    exec_postgres "
    UPDATE $TABELA_PRODUTOS SET 
        quantity = CASE 
            WHEN quantity > 10 THEN 2
            WHEN quantity > 5 THEN 1
            ELSE 0
        END,
        status = CASE 
            WHEN quantity > 10 THEN 'running_low'
            WHEN quantity > 5 THEN 'running_low'
            ELSE 'out_of_stock'
        END,
        updated_at = NOW() - INTERVAL '2 days'
    WHERE id IN (SELECT id FROM $TABELA_PRODUTOS ORDER BY RANDOM() LIMIT 5);
    "
    
    # Reajustes inflacionarios
    info "📈 Criando padrao inflacionario"
    exec_postgres "
    UPDATE $TABELA_PRODUTOS SET 
        price = price * 1.15,
        updated_at = NOW() - INTERVAL '1 day'
    WHERE price < 100;
    "
    
    # Mudancas de usuarios mais realisticas
    info "👥 Criando mudancas realisticas de usuarios"
    exec_mysql "
    UPDATE $TABELA_USUARIOS SET 
        full_name = CONCAT('Dr. ', full_name),
        address = CONCAT(address, ' - Distrito Medico')
    WHERE id IN (SELECT id FROM (SELECT id FROM $TABELA_USUARIOS ORDER BY RAND() LIMIT 3) tmp);
    
    UPDATE $TABELA_USUARIOS SET 
        full_name = CONCAT(full_name, ' Jr.'),
        address = CONCAT(address, ' - Area Residencial')
    WHERE id IN (SELECT id FROM (SELECT id FROM $TABELA_USUARIOS ORDER BY RAND() LIMIT 4) tmp);
    "
    
    log "✅ Padroes de analise criados"
}

# Mostrar estatisticas finais
show_final_statistics() {
    log "📊 Estatisticas finais dos dados:"
    
    echo ""
    info "=== PRODUTOS ==="
    exec_postgres "
    SELECT 
        COUNT(*) as total_produtos,
        ROUND(AVG(price), 2) as preco_medio,
        SUM(quantity) as estoque_total,
        COUNT(CASE WHEN status = 'in_stock' THEN 1 END) as em_estoque,
        COUNT(CASE WHEN status = 'running_low' THEN 1 END) as estoque_baixo,
        COUNT(CASE WHEN status = 'out_of_stock' THEN 1 END) as sem_estoque
    FROM $TABELA_PRODUTOS;
    "
    
    echo ""
    info "=== RANGE DE PRECOS ==="
    exec_postgres "
    SELECT 
        ROUND(MIN(price), 2) as preco_minimo,
        ROUND(MAX(price), 2) as preco_maximo,
        ROUND(AVG(price), 2) as preco_medio,
        ROUND(STDDEV(price), 2) as desvio_padrao
    FROM $TABELA_PRODUTOS;
    "
    
    echo ""
    info "=== USUARIOS ==="
    exec_mysql "
    SELECT 
        COUNT(*) as total_usuarios,
        COUNT(DISTINCT SUBSTRING_INDEX(full_name, ' ', 1)) as primeiros_nomes_unicos,
        AVG(CHAR_LENGTH(full_name)) as tamanho_medio_nome,
        AVG(CHAR_LENGTH(address)) as tamanho_medio_endereco
    FROM $TABELA_USUARIOS;
    "
    
    echo ""
    info "=== TOP 5 PRODUTOS MAIS CAROS ==="
    exec_postgres "
    SELECT name_description, price, quantity, status 
    FROM $TABELA_PRODUTOS 
    ORDER BY price DESC 
    LIMIT 5;
    "
    
    echo ""
    info "=== TOP 5 PRODUTOS COM MAIOR ESTOQUE ==="
    exec_postgres "
    SELECT name_description, quantity, price, status 
    FROM $TABELA_PRODUTOS 
    ORDER BY quantity DESC 
    LIMIT 5;
    "
    
    echo ""
    info "=== DISTRIBUICAO POR STATUS ==="
    exec_postgres "
    SELECT status, COUNT(*) as quantidade
    FROM $TABELA_PRODUTOS 
    GROUP BY status;
    "
    
    echo ""
    log "✅ Dados prontos para analise no Superset!"
    info "💡 Sugestao: Execute seu pipeline de dados agora para indexar no Elasticsearch"
}

# Menu principal
main_menu() {
    echo ""
    echo "=============================================="
    echo "📈 GERADOR DE DADOS PARA RELATORIOS SUPERSET"
    echo "=============================================="
    echo ""
    echo "Este script ira:"
    echo "• ➕ Adicionar 17 novos produtos"
    echo "• 👥 Adicionar 17 novos usuarios"  
    echo "• 🔄 Fazer ~20 alteracoes em cada produto"
    echo "• 👤 Fazer ~20 alteracoes em cada usuario"
    echo "• 📊 Criar padroes interessantes para analise"
    echo ""
    echo "Escolha uma opcao:"
    echo "1) 🚀 Executar tudo (RECOMENDADO)"
    echo "2) 📦 Apenas adicionar produtos"
    echo "3) 👥 Apenas adicionar usuarios"
    echo "4) 🔄 Apenas simular alteracoes de produtos"
    echo "5) 👤 Apenas simular alteracoes de usuarios"
    echo "6) 🎨 Apenas criar padroes de analise"
    echo "7) 📊 Mostrar estatisticas atuais"
    echo "0) ❌ Sair"
    echo ""
    read -p "Digite sua escolha: " choice
    
    case $choice in
        1)
            check_containers
            check_existing_data
            add_17_products
            add_17_users
            simulate_product_updates
            simulate_user_updates
            create_analysis_patterns
            show_final_statistics
            ;;
        2)
            check_containers
            add_17_products
            ;;
        3)
            check_containers
            add_17_users
            ;;
        4)
            check_containers
            simulate_product_updates
            ;;
        5)
            check_containers
            simulate_user_updates
            ;;
        6)
            check_containers
            create_analysis_patterns
            ;;
        7)
            check_containers
            show_final_statistics
            ;;
        0)
            log "👋 Saindo..."
            exit 0
            ;;
        *)
            error "Opcao invalida!"
            main_menu
            ;;
    esac
}

# Executar menu principal se for execucao direta
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_menu
fi
