#!/bin/bash
query_runner=( psql --set=ON_ERROR_STOP=1 --username="$POSTGRES_USER" --no-psqlrc )

if [ -n "$POSTGRES_DB" ]; then
    query_runner+=( --dbname="$POSTGRES_DB" )
fi

if [ -n "$POSTGRES_HOST" ]; then
    query_runner+=( --host="$POSTGRES_HOST" )
fi	

"${query_runner[@]}" "$@"