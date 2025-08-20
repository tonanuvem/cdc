# Se faltar memoria, poderia dar um Stop : nifi e elasticsearch

# Download the docker-compose.yaml file
wget  -O docker-compose-airflow.yaml 'https://airflow.apache.org/docs/apache-airflow/stable/docker-compose.yaml'
wget 'https://airflow.apache.org/docs/apache-airflow/2.3.3/airflow.sh'
chmod +x airflow.sh

# Make expected directories and set an expected environment variable
# mkdir -p ./dags ./logs ./plugins ./config
mkdir -p ./logs ./plugins ./config
echo -e "AIRFLOW_UID=$(id -u)" > .env

# Initialize the database
docker-compose -f docker-compose-airflow.yaml up -d airflow-init 

# Start up all services
docker-compose -f docker-compose-airflow.yaml up -d


IP=$(curl checkip.amazonaws.com)

echo "Acessar $IP:8080 com username/password: airflow "
