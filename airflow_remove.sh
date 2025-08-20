docker-compose -f docker-compose-airflow.yaml down -v && docker-compose -f docker-compose-airflow.yaml rm
docker volume rm cdc_postgres-db-volume
