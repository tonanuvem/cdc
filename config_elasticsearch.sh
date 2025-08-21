# aguarda o ES subir

echo ""
echo ""
until docker exec elasticsearch curl -s -u elastic:changeme http://localhost:9200/_cluster/health | grep -q '"status"'; do
  printf "."; sleep 5
done

echo ""

# cria o pipeline
docker exec elasticsearch curl -s -u elastic:changeme -X PUT "http://localhost:9200/_ingest/pipeline/add_indexed_at" \
  -H 'Content-Type: application/json' \
  -d '{
        "description": "Adiciona data/hora de indexação automaticamente",
        "processors": [
          { "set": { "field": "indexed_at", "value": "{{_ingest.timestamp}}" } }
        ]
      }'

# cria o índice já associado ao pipeline
docker exec elasticsearch curl -s -u elastic:changeme -X PUT "http://localhost:9200/relatorios" \
  -H 'Content-Type: application/json' \
  -d '{
        "settings": {
          "index": {
            "default_pipeline": "add_indexed_at"
          }
        }
      }'

echo ""
echo ""
echo "🎉 Elasticsearch configurado com pipeline + índice!"
