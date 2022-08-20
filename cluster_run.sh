docker stack deploy -c docker-stack.yml cdc

echo ""
echo "Aguardando os serviços entrarem em estado Running."

while [ "$(docker stack ps cdc | grep Running | grep Running | wc -l)" != "12" ]; do printf "." && sleep 1 done

echo ""
sh config_cdc.sh
echo ""
docker service ls
echo ""
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
echo ""
