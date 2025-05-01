# Cria as imagens com os arquivos necessários, evitando usado de volumes para mapear esses arquivos

docker build -t tonanuvem/kowl:conf -f ./Dockerfile/Dockerfile.tonanuvem.kowl .
docker build -t tonanuvem/mysql:usuarios_v5.7 -f ./Dockerfile/Dockerfile.mysql.usuarios_v5.7 .
docker build -t tonanuvem/mysql:usuarios_v9 -f ./Dockerfile/Dockerfile.mysql.usuarios_v9 .
docker build -t tonanuvem/postgres:produtos -f ./Dockerfile/Dockerfile.postgres.produtos .
docker build -t tonanuvem/nifi:cdc -f ./Dockerfile/Dockerfile.nifi.cdc .
docker build -t tonanuvem/pgadmin:cdc -f ./Dockerfile/Dockerfile.pgadmin.cdc .

# Publicar as 5 imagens:
# docker push tonanuvem/kowl:conf && docker push tonanuvem/mysql:usuarios && docker push tonanuvem/postgres:produtos && docker push tonanuvem/nifi:cdc && docker push tonanuvem/pgadmin:cdc
