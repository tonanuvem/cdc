#!/bin/bash

# Script para inserção de dados em lote para demonstração dos relatórios
# Adiciona 17 produtos + 17 usuários e faz ~20 alterações em cada um

set -e

echo "🚀 Iniciando inserção de dados em lote para demonstração de relatórios..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
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

# Verificar se os containers estão rodando
check_containers() {
    log "Verificando se os containers estão rodando..."
    
    if ! docker ps | grep -q postgresdb; then
        error "Container postgresdb não está rodando!"
        exit 1
    fi
    
    if ! docker ps | grep -q mysqldb; then
        error "Container mysqldb não está rodando!"
        exit 1
    fi
    
    log "✅ Todos os containers estão rodando"
}

# Função para executar SQL no PostgreSQL
exec_postgres() {
    docker exec -i postgresdb psql -U postgres -d postgres -c "$1"
}

# Função para executar SQL no MySQL
exec_mysql() {
    docker exec -i mysqldb mysql -u admin -padmin usuarios -e "$1"
}

# Verificar dados existentes
check_existing_data() {
    log "Verificando dados existentes..."
    
    EXISTING_PRODUCTS=$(docker exec -i postgresdb psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM produtos;" | tr -d ' ')
    EXISTING_USERS=$(docker exec -i mysqldb mysql -u admin -padmin usuarios -N -e "SELECT COUNT(*) FROM usuarios;" | tr -d ' ')
    
    info "Produtos existentes: $EXISTING_PRODUCTS"
    info "Usuários existentes: $EXISTING_USERS"
    
    if [ "$EXISTING_PRODUCTS" -lt 3 ] || [ "$EXISTING_USERS" -lt 3 ]; then
        warn "Menos de 3 produtos/usuários existentes. Continuando mesmo assim..."
    fi
}

# Inserir 17 novos produtos
add_17_products() {
    log "Adicionando 17 novos produtos..."
    
    exec_postgres "
    INSERT INTO produtos (name_description, price, quantity, status, created_at) VALUES 
    ('Camiseta básica branca', 35.90, 25, 'in_stock', NOW() - INTERVAL '60 days'),
    ('Calça jeans slim azul', 89.90, 12, 'in_stock', NOW() - INTERVAL '58 days'),
    ('Tênis casual branco', 199.00, 8, 'in_stock', NOW() - INTERVAL '56 days'),
    ('Jaqueta bomber preta', 149.90, 6, 'in_stock', NOW() - INTERVAL '54 days'),
    ('Shorts jeans desbotado', 59.90, 15, 'in_stock', NOW() - INTERVAL '52 days'),
    ('Sapato social preto', 179.90, 4, 'low_stock', NOW() - INTERVAL '50 days'),
    ('Boné snapback azul', 45.90, 20, 'in_stock', NOW() - INTERVAL '48 days'),
    ('Moletom capuz cinza', 89.90, 10, 'in_stock', NOW() - INTERVAL '46 days'),
    ('Regata fitness preta', 29.90, 30, 'in_stock', NOW() - INTERVAL '44 days'),
    ('Calça moletom jogger', 69.90, 8, 'in_stock', NOW() - INTERVAL '42 days'),
    ('Chinelo slide preto', 39.90, 50, 'in_stock', NOW() - INTERVAL '40 days'),
    ('Camisa social branca', 99.90, 7, 'in_stock', NOW() - INTERVAL '38 days'),
    ('Bermuda tactel verde', 49.90, 18, 'in_stock', NOW() - INTERVAL '36 days'),
    ('Tênis running vermelho', 249.90, 5, 'low_stock', NOW() - INTERVAL '34 days'),
    ('Blusa tricot bege', 79.90, 12, 'in_stock', NOW() - INTERVAL '32 days'),
    ('Calça cargo marrom', 109.90, 6, 'in_stock', NOW() - INTERVAL '30 days'),
    ('Sandália couro marrom', 129.90, 9, 'in_stock', NOW() - INTERVAL '28 days');
    "
    
    log "✅ 17 novos produtos adicionados"
}

# Inserir 17 novos usuários
add_17_users() {
    log "Adicionando 17 novos usuários..."
    
    exec_mysql "
    INSERT INTO usuarios (full_name, address, created_at) VALUES 
    ('Bruce Banner', 'Stark Labs Building', DATE_SUB(NOW(), INTERVAL 60 DAY)),
    ('Natasha Romanoff', 'SHIELD Headquarters', DATE_SUB(NOW(), INTERVAL 58 DAY)),
    ('Steve Rogers', 'Brooklyn Heights', DATE_SUB(NOW(), INTERVAL 56 DAY)),
    ('Thor Odinson', 'Asgard Palace', DATE_SUB(NOW(), INTERVAL 54 DAY)),
    ('Clint Barton', 'Farmhouse Iowa', DATE_SUB(NOW(), INTERVAL 52 DAY)),
    ('Wanda Maximoff', 'Westview Avenue', DATE_SUB(NOW(), INTERVAL 50 DAY)),
    ('Vision', 'Avengers Compound', DATE_SUB(NOW(), INTERVAL 48 DAY)),
    ('Sam Wilson', 'Washington DC Base', DATE_SUB(NOW(), INTERVAL 46 DAY)),
    ('Bucky Barnes', 'Brooklyn Apartment', DATE_SUB(NOW(), INTERVAL 44 DAY)),
    ('Scott Lang', 'San Francisco Bay', DATE_SUB(NOW(), INTERVAL 42 DAY)),
    ('Hope van Dyne', 'Pym Technologies', DATE_SUB(NOW(), INTERVAL 40 DAY)),
    ('Carol Danvers', 'Space Station Alpha', DATE_SUB(NOW(), INTERVAL 38 DAY)),
    ('Stephen Strange', 'Sanctum Sanctorum', DATE_SUB(NOW(), INTERVAL 36 DAY)),
    ('T\\'Challa', 'Wakanda Palace', DATE_SUB(NOW(), INTERVAL 34 DAY)),
    ('Shuri', 'Wakanda Lab Center', DATE_SUB(NOW(), INTERVAL 32 DAY)),
    ('Peter Quill', 'Milano Spaceship', DATE_SUB(NOW(), INTERVAL 30 DAY)),
    ('Gamora', 'Guardians Base', DATE_SUB(NOW(), INTERVAL 28 DAY));
    "
    
    log "✅ 17 novos usuários adicionados"
}

# Fazer ~20 alterações em produtos (distribuído ao longo do tempo)
simulate_product_updates() {
    log "Simulando ~20 alterações por produto ao longo do tempo..."
    
    # Get all product IDs
    PRODUCT_IDS=$(docker exec -i postgresdb psql -U postgres -d postgres -t -c "SELECT id FROM produtos ORDER BY id;" | tr -d ' ')
    
    for product_id in $PRODUCT_IDS; do
        if [ -z "$product_id" ]; then
            continue
        fi
        
        info "Criando histórico para produto ID: $product_id"
        
        # 20 alterações por produto distribuídas em 60 dias
        for i in {1..20}; do
            # Variação aleatória de preço (-20% a +30%)
            PRICE_VARIATION=$(shuf -i 80-130 -n 1)  # 80% a 130% do preço atual
            
            # Variação de quantidade (1 a 50)
            QTY_VARIATION=$(shuf -i 1-50 -n 1)
            
            # Status baseado na quantidade
            if [ "$QTY_VARIATION" -le 3 ]; then
                STATUS="'low_stock'"
            elif [ "$QTY_VARIATION" -eq 0 ]; then
                STATUS="'out_of_stock'"
            else
                STATUS="'in_stock'"
            fi
            
            # Dias atrás para esta alteração
            DAYS_AGO=$((60 - i * 3))
            if [ "$DAYS_AGO" -lt 0 ]; then
                DAYS_AGO=0
            fi
            
            exec_postgres "
            UPDATE produtos SET 
                price = ROUND((price * $PRICE_VARIATION / 100)::numeric, 2),
                quantity = $QTY_VARIATION,
                status = $STATUS,
                updated_at = NOW() - INTERVAL '$DAYS_AGO days'
            WHERE id = $product_id;
            " > /dev/null 2>&1
            
            # Sleep para não sobrecarregar
            sleep 0.1
        done
    done
    
    log "✅ Simulação de alterações de produtos concluída"
}

# Fazer ~20 alterações em usuários
simulate_user_updates() {
    log "Simulando ~20 alterações por usuário ao longo do tempo..."
    
    # Arrays de variações para nomes e endereços
    declare -a NAME_PREFIXES=("Dr." "Prof." "Sr." "Sra." "Mr." "Ms." "")
    declare -a NAME_SUFFIXES=("Jr." "Sr." "II" "III" "PhD" "MD" "")
    declare -a STREET_TYPES=("Street" "Avenue" "Boulevard" "Road" "Lane" "Drive" "Way")
    declare -a CITIES=("NYC" "LA" "Chicago" "Miami" "Boston" "Seattle" "Denver")
    
    # Get all user IDs
    USER_IDS=$(docker exec -i mysqldb mysql -u admin -padmin usuarios -N -e "SELECT id FROM usuarios ORDER BY id;" | tr -d ' ')
    
    for user_id in $USER_IDS; do
        if [ -z "$user_id" ]; then
            continue
        fi
        
        info "Criando histórico para usuário ID: $user_id"
        
        # Get current user data
        CURRENT_USER=$(docker exec -i mysqldb mysql -u admin -padmin usuarios -N -e "SELECT full_name FROM usuarios WHERE id = $user_id;")
        BASE_NAME=$(echo "$CURRENT_USER" | sed 's/Dr\.\|Prof\.\|Sr\.\|Sra\.\|Mr\.\|Ms\.\|Jr\.\|Sr\.\|II\|III\|PhD\|MD//g' | xargs)
        
        # 20 alterações por usuário
        for i in {1..20}; do
            # Variação no nome (adicionar/remover prefixos/sufixos)
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
            
            # Variação no endereço
            STREET_NUM=$((RANDOM % 9999 + 1))
            STREET_NAME="Building $((RANDOM % 100 + 1))"
            STREET_TYPE=${STREET_TYPES[$RANDOM % ${#STREET_TYPES[@]}]}
            CITY=${CITIES[$RANDOM % ${#CITIES[@]}]}
            NEW_ADDRESS="$STREET_NUM $STREET_NAME $STREET_TYPE $CITY"
            
            # Dias atrás para esta alteração
            DAYS_AGO=$((60 - i * 3))
            if [ "$DAYS_AGO" -lt 0 ]; then
                DAYS_AGO=0
            fi
            
            exec_mysql "
            UPDATE usuarios SET 
                full_name = '$NEW_NAME',
                address = '$NEW_ADDRESS',
                updated_at = DATE_SUB(NOW(), INTERVAL $DAYS_AGO DAY)
            WHERE id = $user_id;
            " > /dev/null 2>&1
            
            # Sleep para não sobrecarregar
            sleep 0.1
        done
    done
    
    log "✅ Simulação de alterações de usuários concluída"
}

# Criar padrões interessantes para análise
create_analysis_patterns() {
    log "Criando padrões interessantes para análise..."
    
    # Produto sazonal: aumentar preços de alguns produtos específicos
    info "🌞 Criando padrão sazonal - produtos de verão"
    exec_postgres "
    UPDATE produtos SET 
        price = price * 1.25,
        updated_at = NOW() - INTERVAL '5 days'
    WHERE name_description LIKE '%shorts%' 
       OR name_description LIKE '%regata%' 
       OR name_description LIKE '%chinelo%';
    "
    
    # Black Friday: grandes descontos
    info "🛍️ Criando padrão Black Friday - descontos massivos"
    exec_postgres "
    UPDATE produtos SET 
        price = price * 0.60,
        quantity = quantity + 20,
        updated_at = NOW() - INTERVAL '10 days'
    WHERE id IN (SELECT id FROM produtos ORDER BY RANDOM() LIMIT 8);
    "
    
    # Fim de estoque gradual
    info "📉 Criando padrão de fim de estoque"
    exec_postgres "
    UPDATE produtos SET 
        quantity = CASE 
            WHEN quantity > 10 THEN 2
            WHEN quantity > 5 THEN 1
            ELSE 0
        END,
        status = CASE 
            WHEN quantity > 10 THEN 'low_stock'
            WHEN quantity > 5 THEN 'low_stock'
            ELSE 'out_of_stock'
        END,
        updated_at = NOW() - INTERVAL '2 days'
    WHERE id IN (SELECT id FROM produtos ORDER BY RANDOM() LIMIT 5);
    "
    
    # Reajustes inflacionários
    info "📈 Criando padrão inflacionário"
    exec_postgres "
    UPDATE produtos SET 
        price = price * 1.15,
        updated_at = NOW() - INTERVAL '1 day'
    WHERE price < 100;
    "
    
    # Mudanças de usuários mais realistas
    info "👥 Criando mudanças realistas de usuários"
    exec_mysql "
    UPDATE usuarios SET 
        full_name = CONCAT('Dr. ', full_name),
        address = CONCAT(address, ' - Medical District')
    WHERE id IN (SELECT id FROM (SELECT id FROM usuarios ORDER BY RAND() LIMIT 3) tmp);
    
    UPDATE usuarios SET 
        full_name = CONCAT(full_name, ' Jr.'),
        address = CONCAT(address, ' - Residential Area')
    WHERE id IN (SELECT id FROM (SELECT id FROM usuarios ORDER BY RAND() LIMIT 4) tmp);
    "
    
    log "✅ Padrões de análise criados"
}

# Mostrar estatísticas finais
show_final_statistics() {
    log "📊 Estatísticas finais dos dados:"
    
    echo ""
    info "=== PRODUTOS ==="
    exec_postgres "
    SELECT 
        COUNT(*) as total_produtos,
        ROUND(AVG(price), 2) as preco_medio,
        SUM(quantity) as estoque_total,
        COUNT(CASE WHEN status = 'in_stock' THEN 1 END) as em_estoque,
        COUNT(CASE WHEN status = 'low_stock' THEN 1 END) as estoque_baixo,
        COUNT(CASE WHEN status = 'out_of_stock' THEN 1 END) as sem_estoque
    FROM produtos;
    "
    
    echo ""
    info "=== RANGE DE PREÇOS ==="
    exec_postgres "
    SELECT 
        ROUND(MIN(price), 2) as preco_minimo,
        ROUND(MAX(price), 2) as preco_maximo,
        ROUND(AVG(price), 2) as preco_medio,
        ROUND(STDDEV(price), 2) as desvio_padrao
    FROM produtos;
    "
    
    echo ""
    info "=== USUÁRIOS ==="
    exec_mysql "
    SELECT 
        COUNT(*) as total_usuarios,
        COUNT(DISTINCT SUBSTRING_INDEX(full_name, ' ', 1)) as primeiros_nomes_unicos,
        AVG(CHAR_LENGTH(full_name)) as tamanho_medio_nome,
        AVG(CHAR_LENGTH(address)) as tamanho_medio_endereco
    FROM usuarios;
    "
    
    echo ""
    info "=== TOP 5 PRODUTOS MAIS CAROS ==="
    exec_postgres "
    SELECT name_description, price, quantity, status 
    FROM produtos 
    ORDER BY price DESC 
    LIMIT 5;
    "
    
    echo ""
    info "=== TOP 5 PRODUTOS COM MAIOR ESTOQUE ==="
    exec_postgres "
    SELECT name_description, quantity, price, status 
    FROM produtos 
    ORDER BY quantity DESC 
    LIMIT 5;
    "
    
    echo ""
    info "=== DISTRIBUIÇÃO POR STATUS ==="
    exec_postgres "
    SELECT status, COUNT(*) as quantidade
    FROM produtos 
    GROUP BY status;
    "
    
    echo ""
    log "✅ Dados prontos para análise no Superset!"
    info "💡 Sugestão: Execute seu pipeline de dados agora para indexar no Elasticsearch"
}

# Menu principal
main_menu() {
    echo ""
    echo "=============================================="
    echo "📈 GERADOR DE DADOS PARA RELATÓRIOS SUPERSET"
    echo "=============================================="
    echo ""
    echo "Este script irá:"
    echo "• ➕ Adicionar 17 novos produtos"
    echo "• 👥 Adicionar 17 novos usuários"  
    echo "• 🔄 Fazer ~20 alterações em cada produto"
    echo "• 👤 Fazer ~20 alterações em cada usuário"
    echo "• 📊 Criar padrões interessantes para análise"
    echo ""
    echo "Escolha uma opção:"
    echo "1) 🚀 Executar tudo (RECOMENDADO)"
    echo "2) 📦 Apenas adicionar produtos"
    echo "3) 👥 Apenas adicionar usuários"
    echo "4) 🔄 Apenas simular alterações de produtos"
    echo "5) 👤 Apenas simular alterações de usuários"
    echo "6) 🎨 Apenas criar padrões de análise"
    echo "7) 📊 Mostrar estatísticas atuais"
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
            error "Opção inválida!"
            main_menu
            ;;
    esac
}

# Executar menu principal se for execução direta
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_menu
fi
