#!/usr/bin/env python3
"""
Script para configurar CloudBeaver automaticamente via API GraphQL
Cria usuário admin e conexões compartilhadas
"""
import requests
import time
import sys

BASE_URL = "http://localhost:8978"
API_URL = f"{BASE_URL}/api/gql"

def gql(query, cookies=None):
    """Executa query GraphQL"""
    try:
        r = requests.post(API_URL, json={"query": query}, cookies=cookies, timeout=10)
        return r.json(), r.cookies
    except Exception as e:
        print(f"❌ Erro na requisição: {e}")
        return None, None

print("🚀 Configurando CloudBeaver...\n")

# 1. Abrir sessão
print("1️⃣  Abrindo sessão...")
result, cookies = gql('mutation { openSession { valid } }')
if not result or not result.get("data", {}).get("openSession", {}).get("valid"):
    print("❌ Falha ao abrir sessão")
    sys.exit(1)
print("✅ Sessão aberta\n")

# 2. Verificar se precisa configurar (primeira vez)
print("2️⃣  Verificando configuração inicial...")
result, cookies = gql('query { serverConfig { configurationMode anonymousAccessEnabled } }', cookies)
config_mode = result.get("data", {}).get("serverConfig", {}).get("configurationMode", False)

if config_mode:
    print("⚙️  Modo de configuração ativo - completando wizard...")
    
    # Finalizar configuração inicial
    finish_query = '''
    mutation {
      configureServer(configuration: {
        serverName: "CloudBeaver CDC"
        serverURL: "http://localhost:8978"
        adminName: "admin"
        adminPassword: "admin"
        anonymousAccessEnabled: true
        authenticationEnabled: true
        customConnectionsEnabled: true
        publicCredentialsSaveEnabled: true
      }) {
        valid
      }
    }
    '''
    result, cookies = gql(finish_query, cookies)
    if result and result.get("data", {}).get("configureServer", {}).get("valid"):
        print("✅ Configuração inicial concluída\n")
        time.sleep(2)
    else:
        print(f"⚠️  Erro na configuração: {result}\n")
else:
    print("✅ CloudBeaver já configurado\n")

# 3. Criar conexões
print("3️⃣  Criando conexões...\n")

connections = [
    {
        "name": "Postgres - Produtos",
        "driver": "postgresql:postgres-jdbc",
        "host": "postgresdb",
        "port": "5432",
        "database": "postgres",
        "user": "postgres",
        "password": "admin"
    },
    {
        "name": "MySQL - Usuários",
        "driver": "mysql:mysql8",
        "host": "mysqldb",
        "port": "3306",
        "database": "usuarios",
        "user": "admin",
        "password": "admin"
    }
]

for conn in connections:
    query = f'''
    mutation {{
      createConnection(config: {{
        name: "{conn["name"]}"
        driverId: "{conn["driver"]}"
        host: "{conn["host"]}"
        port: "{conn["port"]}"
        databaseName: "{conn["database"]}"
        credentials: {{user: "{conn["user"]}", password: "{conn["password"]}"}}
        saveCredentials: true
      }}) {{
        id
        name
      }}
    }}
    '''
    result, cookies = gql(query, cookies)
    if result and result.get("data", {}).get("createConnection"):
        c = result["data"]["createConnection"]
        print(f"   ✅ {c['name']}")
    else:
        errors = result.get("errors", []) if result else []
        print(f"   ⚠️  {conn['name']}: {errors[0].get('message', 'Erro desconhecido') if errors else 'Erro'}")

# 4. Verificar acesso anônimo
print("\n4️⃣  Verificando acesso anônimo...")
result, new_cookies = gql('mutation { openSession { valid } }')
result, new_cookies = gql('query { userConnections { id name } }', new_cookies)

connections_list = result.get("data", {}).get("userConnections", []) if result else []
if connections_list:
    print(f"✅ {len(connections_list)} conexão(ões) visível(is) para usuário anônimo:")
    for c in connections_list:
        print(f"   - {c['name']}")
else:
    print("⚠️  Conexões criadas mas não visíveis para usuário anônimo")
    print("   (Isso é esperado - conexões são privadas por padrão)")

print(f"\n🎉 Concluído! Acesse: {BASE_URL}")
print("   Login: admin / admin")
