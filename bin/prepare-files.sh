#!/usr/bin/env bash

docker_process_init_files() {
    local f
	for f; do
		case "$f" in
			*.csv.gz)  printf '%s: extracting %s\n' "$0" "$f"; gunzip "$f"; printf '\n' ;;
			*)         printf '%s: ignoring %s\n' "$0" "$f" ;;
		esac
		printf '\n'
	done
}

docker_process_init_files $1