docker-compose stop && docker-compose rm -f && docker volume prune -f && git pull
docker volume rm cdc_esdata cdc_mysqldata cdc_pgadmindata cdc_postgresdata
