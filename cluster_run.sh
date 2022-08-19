# Liberando a porta no caso de rodar no Cloud9
sudo service mysql stop
chmod 755 postgres_init_database.sh

docker stack deploy -c docker-stack.yml cdc

echo ""
echo "Aguardando a configuração do Debezium CDC (Change Data Capture)."
while [ "$(docker service logs cdc_connect 2>&1 | grep "Finished starting connectors and tasks" | wc -l)" != "1" ]; do
  printf "."
  sleep 1
done
echo ""
sh config_cdc.sh
echo ""
echo "Aguardando todos os 12 serviços entrarem em estado Running."
while [ "$(docker stack ps --no-trunc cdc 2>&1 | grep "Running         Running" | wc -l)" != "12" ]; do
  printf "."
  sleep 1
done
echo ""
docker service ls
echo ""
echo "Config OK"
IP=$(curl -s checkip.amazonaws.com)
echo ""
echo "URLs do projeto:"
echo ""
echo " - VISUALIZADOR    : http://$IP:8060"
echo ""
echo " - KAFKA UI        : http://$IP:8070"
echo ""
echo " - PostGres UI     : http://$IP:8080 ( login = admin@admin.com / senha = admin )" 
echo " - MySQL UI        : http://$IP:8082 ( login = admin / senha = admin )"
echo ""
echo " - NIFI            : http://$IP:8090/nifi"
echo ""
