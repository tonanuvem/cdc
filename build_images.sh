# Cria as imagens com os arquivos necessários, evitando usado de volumes para mapear esses arquivos

docker build -t tonanuvem/kowl:conf -f ./Dockerfile/Dockerfile.tonanuvem.kowl .
docker build -t tonanuvem/mysql:usuarios -f ./Dockerfile/Dockerfile.mysql.usuarios .
docker build -t tonanuvem/postgres:produtos -f ./Dockerfile/Dockerfile.postgres.produtos .
docker build -t tonanuvem/nifi:cdc -f ./Dockerfile/Dockerfile.nifi.cdc .
docker build -t tonanuvem/pgadmin:cdc -f ./Dockerfile/Dockerfile.pgadmin.cdc .
