# Liberando a porta no caso de rodar no Cloud9
sudo service mysql stop

#chmod 755 mysql_init_database.sql

docker-compose -f docker-compose-superset.yaml up -d

echo ""
echo "Aguardando a configuração."
while [ "$(docker logs superset_app 2>&1 | grep "Listening at" | wc -l)" != "1" ]; do
  printf "."
  sleep 1
done
echo ""

#### sh config_superset.sh

# Setup your local admin account

docker exec -it superset_app superset fab create-admin \
              --username fiap \
              --firstname Superset \
              --lastname fiap \
              --email admin@admin.com \
              --password fiap

# Migrate local DB to latest

docker exec -it superset_app superset db upgrade

#Load Examples
# docker exec -it superset_app superset load_examples

# Setup roles

docker exec -it superset_app superset init
