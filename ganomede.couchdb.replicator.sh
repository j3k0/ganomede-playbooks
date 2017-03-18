#!/bin/bash

declare -a HOSTS
{% if config.couchdb.deploy %}
  HOSTS[0]="couchdb-0.{{dns_domain}}:{{config.couchdb.port}}"
  HOSTS[1]="couchdb-1.{{dns_domain}}:{{config.couchdb.port}}"
{% else %}
  HOSTS[0]="{{ config.couchdb.external_hosts[0] }}"
  HOSTS[1]="{{ config.couchdb.external_hosts[1] }}"
{% endif %}
URL="http://${HOSTS[0]}"
URL_ALT="http://${HOSTS[1]}"

DATABASES="
{% for database in couchdb_databases %}
  {{ couchdb_database_prefix }}{{ database }}
{% endfor %}
"

for DB_NAME in $DATABASES; do

  echo "Make sure DB exists"
  curl -X PUT "$URL/$DB_NAME"
  curl -X PUT "$URL_ALT/$DB_NAME"

  echo "New replication:"
  cat << EOF > tmp-replicator.json
{
"_id": "replicate-$DB_NAME-0-to-1",
"create_target": true,
"continuous": true,
"source": "http://${HOSTS[0]}/$DB_NAME",
"target": "http://${HOSTS[1]}/$DB_NAME"
}
EOF

  cat tmp-replicator.json
  curl -H "Content-type: application/json" $URL/_replicator -d @tmp-replicator.json
  echo

  echo "New replication:"
  cat << EOF > tmp-replicator.json
{
"_id": "replicate-$DB_NAME-1-to-0",
"create_target": true,
"continuous": true,
"source": "http://${HOSTS[1]}/$DB_NAME",
"target": "http://${HOSTS[0]}/$DB_NAME"
}
EOF

  cat tmp-replicator.json
  curl -H "Content-type: application/json" $URL/_replicator -d @tmp-replicator.json
  echo
done

