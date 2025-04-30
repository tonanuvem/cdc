# Postgres:

docker exec -it cdc-postgresdb-1 bash -c "CONF=/var/lib/postgresql/data/postgresql.conf; EXT=pg_stat_statements; if grep -q '^shared_preload_libraries' \$CONF; then CUR=\$(grep '^shared_preload_libraries' \$CONF | cut -d\"'\" -f2); if echo \$CUR | grep -qw \$EXT; then echo '\$EXT já está presente'; else sed -i \"s|^\(shared_preload_libraries *= *'\)[^']*|\1\$EXT,\$CUR|\" \$CONF && echo '\$EXT adicionado'; fi; else echo \"shared_preload_libraries = '\$EXT'\" >> \$CONF && echo '\$EXT configurado'; fi"
docker restart cdc-postgresdb-1
docker exec -it cdc-postgresdb-1 psql -U postgres -d postgres -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"

