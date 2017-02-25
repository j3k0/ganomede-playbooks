#!/bin/bash

{% if index == "0" %}
OTHER_INDEX="1"
{% else %}
OTHER_INDEX="0"
{% endif %}

DATABASES="
{% for database in couchdb_databases %}
  {{ couchdb_database_prefix }}{{ database }}
{% endfor %}
"
for DB_NAME in $DATABASES; do
  echo "New replication:"
cat << EOF > tmp-replicator.json
{
"_id": "replicate-$DB_NAME-$OTHER_INDEX-to-{{index}}",
"create_target": true,
"continuous": true,
"source": "http://couchdb-$OTHER_INDEX.{{dns_domain}}:{{config.couchdb.port}}/$DB_NAME",
"target": "http://couchdb-{{index}}.{{dns_domain}}:{{config.couchdb.port}}/$DB_NAME"
}
EOF

  cat tmp-replicator.json
  #sleep 1
  #echo 3
  #sleep 1
  #echo 2
  #sleep 1
  #echo 1
  #sleep 1
  #echo
  curl -H "Content-type: application/json" http://couchdb-{{index}}.{{dns_domain}}:{{config.couchdb.port}}/_replicator -d @tmp-replicator.json
  echo
done
