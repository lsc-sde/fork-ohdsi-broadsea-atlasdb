#!/usr/bin/env bash
# This script is based upon the docker-entrypoint.sh but stripped back to allow it to be used 
# to populate a pre-existing database on an external server.

set -Eeo pipefail
# TODO swap to -Eeuo pipefail above (after handling all potentially-unset variables)

# usage: docker_process_init_files [file [file [...]]]
#    ie: docker_process_init_files /always-initdb.d/*
# process initializer files, based on file extensions and permissions
docker_process_init_files() {
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
			*.sql)     printf '%s: running %s\n' "$0" "$f"; process-sql.sh -f "$f"; printf '\n' ;;
			*.sql.gz)  printf '%s: running %s\n' "$0" "$f"; gunzip -c "$f" | process-sql.sh; printf '\n' ;;
			*.sql.xz)  printf '%s: running %s\n' "$0" "$f"; xzcat "$f" | process-sql.sh; printf '\n' ;;
			*.sql.zst) printf '%s: running %s\n' "$0" "$f"; zstd -dc "$f" | process-sql.sh; printf '\n' ;;
			*)         printf '%s: ignoring %s\n' "$0" "$f" ;;
		esac
		printf '\n'
	done
}

/usr/local/bin/prepare-files.sh "/tmp/*"
/usr/local/bin/prepare-files.sh "/tmp/demo_cdm_csv_files/*"

echo "Checking if 'demo_cdm' schema already exists"
SCHEMA_ALREADY_EXISTS=$(echo "SELECT 1 FROM pg_catalog.pg_namespace where nspname = 'demo_cdm';" | process-sql.sh --tuples-only)

if [ $? -ne 0 ]; then
	echo "Error checking schema"
	cat ~/last-cmd.sql
elif [ -z "${SCHEMA_ALREADY_EXISTS}" ]; then
	echo "Schema does not exist, processing init files"
	docker_process_init_files /docker-entrypoint-initdb.d/*
else
	echo "Schema already exists, skipping"
fi
