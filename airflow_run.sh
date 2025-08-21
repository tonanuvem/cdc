# Se faltar memoria, dar um Stop : nifi e elasticsearch
docker-compose stop nifi elasticsearch

# https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html

# https://www.astronomer.io/docs/learn/airflow-kafka

# https://medium.com/apache-airflow/data-engineering-end-to-end-project-part-1-airflow-kafka-cassandra-mongodb-docker-a87f2daec55e
# https://medium.com/apache-airflow/data-engineering-end-to-end-project-part-2-airflow-kafka-cassandra-mongodb-docker-52a2ec7113de

# Download the docker-compose.yaml file
# wget  -O docker-compose-airflow.yaml 'https://airflow.apache.org/docs/apache-airflow/stable/docker-compose.yaml'
# curl -LfO 'https://airflow.apache.org/docs/apache-airflow/3.0.4/airflow.sh'
# chmod +x airflow.sh

# Make expected directories and set an expected environment variable
# mkdir -p ./dags ./logs ./plugins ./config
mkdir -p ./logs ./plugins ./config
echo -e "AIRFLOW_UID=$(id -u)" > .env

# Initialize the database
docker-compose -f docker-compose-airflow.yaml up -d airflow-init 

# Start up all services
docker-compose -f docker-compose-airflow.yaml up -d

echo "Aguardando TOKEN (geralmente 1 min)"
#while [ "$(docker logs cdc-jupyter-1 2>&1 | grep token | grep 127. | wc -l)" != "1" ]; do
#  printf "."
#  sleep 1
#done
echo "Token Pronto."
TOKEN=$(docker logs cdc-jupyter-1 2>&1 | grep token | grep 127. | sed -n 's/.*?token=\([a-f0-9]*\).*/\1/p' | uniq)
echo ""

echo "Configurando conector do Airflow com Kafka"
docker exec -it cdc-airflow-scheduler-1 airflow connections add kafka_airflow_teams \
    --conn-type kafka \
    --conn-host kafka \
    --conn-port 9092 \
    --conn-extra '{"bootstrap.servers": "kafka:9092", "group.id": "kafka_airflow_teams", "security.protocol": "PLAINTEXT", "auto.offset.reset": "beginning"}' 2>/dev/null

IP=$(curl -s checkip.amazonaws.com)
echo ""
echo "URLs do projeto:"
echo ""
echo " - AIRFLOW                       : http://$IP:8080      com username/password: airflow"
echo ""
echo " - JUPYTER PARA EDITAR DAGS      : http://$IP:8880/lab?token=$TOKEN"
echo ""
echo ""

