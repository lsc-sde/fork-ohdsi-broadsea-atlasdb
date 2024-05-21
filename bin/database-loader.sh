#!/usr/bin/env bash
# This script is based upon the docker-entrypoint.sh but stripped back to allow it to be used 
# to populate a pre-existing database on an external server.

set -Eeo pipefail
# TODO swap to -Eeuo pipefail above (after handling all potentially-unset variables)

# usage: docker_process_init_files [file [file [...]]]
#    ie: docker_process_init_files /always-initdb.d/*
# process initializer files, based on file extensions and permissions
docker_process_init_files() {
	# psql here for backwards compatibility "${psql[@]}"
	psql=( docker_process_sql )

	

	printf '\n'
	local f
	for f; do
		case "$f" in
			*.sh)
				# https://github.com/docker-library/postgres/issues/450#issuecomment-393167936
				# https://github.com/docker-library/postgres/pull/452
				if [ -x "$f" ]; then
					printf '%s: running %s\n' "$0" "$f"
					"$f"
				else
					printf '%s: sourcing %s\n' "$0" "$f"
					. "$f"
				fi
				;;
			*.sql)     printf '%s: running %s\n' "$0" "$f"; docker_process_sql -f "$f"; printf '\n' ;;
			*.sql.gz)  printf '%s: running %s\n' "$0" "$f"; gunzip -c "$f" | docker_process_sql; printf '\n' ;;
			*.sql.xz)  printf '%s: running %s\n' "$0" "$f"; xzcat "$f" | docker_process_sql; printf '\n' ;;
			*.sql.zst) printf '%s: running %s\n' "$0" "$f"; zstd -dc "$f" | docker_process_sql; printf '\n' ;;
			*)         printf '%s: ignoring %s\n' "$0" "$f" ;;
		esac
		printf '\n'
	done
}

# Execute sql script, passed via stdin (or -f flag of pqsl)
# usage: docker_process_sql [psql-cli-args]
#    ie: docker_process_sql --dbname=mydb <<<'INSERT ...'
#    ie: docker_process_sql -f my-file.sql
#    ie: docker_process_sql <my-file.sql
docker_process_sql() {
	local query_runner=( psql --set=ON_ERROR_STOP=1 --username="$POSTGRES_USER" --no-psqlrc )
	if [ -n "$POSTGRES_DB" ]; then
		query_runner+=( --dbname="$POSTGRES_DB" )
	fi

	if [ -n "$POSTGRES_HOST" ]; then
		query_runner+=( --host="$POSTGRES_HOST" )
	fi	
	PGHOST= PGHOSTADDR= "${query_runner[@]}" "$@"
}

/usr/local/bin/prepare-files.sh "/tmp/*"
/usr/local/bin/prepare-files.sh "/tmp/demo_cdm_csv_files/*"
schemaAlreadyExists="$(
		POSTGRES_DB= docker_process_sql --tuples-only <<-'EOSQL'
			SELECT 1 FROM pg_catalog.pg_namespace where nspname = 'demo_cdm';
		EOSQL
	)"
	if [ -z "$schemaAlreadyExists" ]; then
		docker_process_init_files /docker-entrypoint-initdb.d/*
	else
		echo "Schema already exists, skipping"
	fi
