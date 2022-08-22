# Liberando a porta no caso de rodar no Cloud9
sudo service mysql stop
chmod 755 postgres_init_database.sh

docker stack deploy -c docker-superset-cluster.yml cdc

echo ""
echo "Aguardando todos os 13 serviços entrarem em estado Running."
while [ "$(docker stack ps --no-trunc cdc 2>&1 | grep "Running         Running" | wc -l)" != "13" ]; do
  printf "."
  sleep 1
done
echo ""
sh config_cdc.sh
echo ""
docker service ls
echo ""

echo "Configurando o SuperSet"
echo ""
# Setup your local admin account
docker exec $(docker ps -q -f name=cdc_superset) \
            superset fab create-admin \
              --username admin \
              --firstname Superset \
              --lastname Admin \
              --email admin@admin.com \
              --password admin
# Migrate local DB to latest
docker exec $(docker ps -q -f name=cdc_superset) superset db upgrade
#Load Examples
# docker exec -it  cdc_superset superset load_examples
# Setup roles
docker exec $(docker ps -q -f name=cdc_superset) superset init
#echo "Loading Dashboard:"
#docker exec -it  cdc_superset superset import-dashboards -p /app/superset_home/superset/dashboard_ETL.zip

echo "Config OK"
IP=$(curl -s checkip.amazonaws.com)
echo ""
echo "URLs do projeto:"
echo ""
echo " - VISUALIZADOR            : http://$IP:8060"
echo ""
echo " - KAFKA UI                : http://$IP:8070"
echo ""
echo " - PostGres UI             : http://$IP:8080 ( login = admin@admin.com / senha = admin )" 
echo " - MySQL UI                : http://$IP:8082 ( login = admin / senha = admin )"
echo ""
echo " - NIFI                    : http://$IP:8090/nifi"
echo " - Kibana (Elastic search) : http://$IP:5601/nifi"
echo " - SUPERSET                : http://$IP:8088   (login = admin, password = admin)"
echo ""
