# Liberando a porta no caso de rodar no Cloud9
sudo service mysql stop
chmod 755 postgres_init_database.sh

docker-compose up -d

echo ""
echo "Aguardando a configuração do Debezium CDC (Change Data Capture)."
while [ "$(docker logs cdc-connect-1 2>&1 | grep "Finished starting connectors and tasks" | wc -l)" != "1" ]; do
  printf "."
  sleep 1
done
echo ""
sh config_cdc.sh
echo "Config OK"
IP=$(curl -s checkip.amazonaws.com)
echo ""
echo "URLs do projeto:"
echo ""
echo " - DEBEZIUM UI             : http://$IP:8074"
echo ""
echo " - KAFKA UI                : http://$IP:8070"
echo ""
echo " - PostGres UI             : http://$IP:30080 ( login = admin@admin.com / senha = admin )" 
echo " - MySQL UI                : http://$IP:8082 ( login = admin / senha = admin )"
echo ""
echo " - NIFI                    : http://$IP:8090/nifi"
echo " - Kibana (Elastic search) : http://$IP:5601"
echo ""
