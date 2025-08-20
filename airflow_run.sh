# Se faltar memoria, poderia dar um Stop : nifi e elasticsearch

# https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html

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


IP=$(curl -s checkip.amazonaws.com)
echo ""
echo "URLs do projeto:"
echo ""
echo " - AIRFLOW                       : http://$IP:8080      com username/password: airflow"
echo ""
echo " - JUPYTER PARA EDITAR DAGS      : http://$IP:8880      senha: admin"
echo ""
echo ""

