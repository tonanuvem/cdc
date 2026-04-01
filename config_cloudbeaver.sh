#!/bin/bash

# Nome do container definido no docker-compose
CONTAINER_NAME="cloudbeaver"

echo "🚀 Configurando CloudBeaver..."

sudo chmod -R 777 ./cloudbeaver  # Permissao

echo "⏳ Aguardando a inicialização do serviço (isso pode levar alguns segundos)..."
IP=$(curl -s checkip.amazonaws.com)

# Loop de verificação de logs
while true; do
    # Verifica se a string "Started JettyServer" aparece nos logs
    
    if docker logs "$CONTAINER_NAME" 2>&1 | grep -q "Started JettyServer"; then
        echo -e "\n✅ CloudBeaver subiu com sucesso!"
        echo "🌐 Acesse em: http://$IP:8978"
        break
    fi

    # Verifica se o container morreu por erro
    STATUS=$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)
    if [ "$STATUS" != "true" ]; then
        echo -e "\n❌ Erro: O container $CONTAINER_NAME parou de rodar."
        docker logs "$CONTAINER_NAME" --tail 20
        exit 1
    fi

    echo -n "."
    sleep 2
done
