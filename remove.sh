docker-compose stop && docker-compose rm -f && docker volume prune -f && git pull
docker volume rm cdc_esdata cdc_mysqldata cdc_pgadmindata cdc_postgresdata
docker volume rm cdc_api_tokens cdc_cloudbeaver-postgres_data cdc_cloudbeaver_certs cdc_trusted_cacerts dbeaver_api_tokens dbeaver_cloudbeaver_certs dbeaver_trusted_cacerts
