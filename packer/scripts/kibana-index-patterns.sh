#!/usr/bin/env bash
set -e

mkdir -p /kibana-index-patterns

echo "Installing Kibana index patterns..."

cat <<EOF >/kibana-index-patterns/filebeat-index.json
{"title":"filebeat-*","timeFieldName":"@timestamp","fields":"[{\"name\":\"source\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"type\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"syslog_severity\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"syslog_pid.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"syslog_timestamp\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"type.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"host\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"host.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"syslog_severity_code\",\"type\":\"number\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"input_type.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"offset\",\"type\":\"number\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"syslog_facility.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"syslog_facility\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"input_type\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"@version.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"syslog_message\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"tags\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"beat.name\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"message.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"_source\",\"type\":\"_source\",\"count\":0,\"scripted\":false,\"indexed\":false,\"analyzed\":false,\"doc_values\":false,\"searchable\":false,\"aggregatable\":false},{\"name\":\"syslog_hostname.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"syslog_pid\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"tags.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"syslog_program\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"beat.hostname.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"beat.name.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"syslog_timestamp.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"received_from\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"@version\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"beat.version\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"source.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"syslog_program.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"received_from.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"syslog_facility_code\",\"type\":\"number\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"message\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"syslog_severity.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"beat.hostname\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"@timestamp\",\"type\":\"date\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"syslog_hostname\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":true,\"doc_values\":false,\"searchable\":true,\"aggregatable\":false},{\"name\":\"received_at\",\"type\":\"date\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"beat.version.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"syslog_message.keyword\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":true,\"analyzed\":false,\"doc_values\":true,\"searchable\":true,\"aggregatable\":true},{\"name\":\"_id\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":false,\"analyzed\":false,\"doc_values\":false,\"searchable\":false,\"aggregatable\":false},{\"name\":\"_type\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":false,\"analyzed\":false,\"doc_values\":false,\"searchable\":true,\"aggregatable\":true},{\"name\":\"_index\",\"type\":\"string\",\"count\":0,\"scripted\":false,\"indexed\":false,\"analyzed\":false,\"doc_values\":false,\"searchable\":false,\"aggregatable\":false},{\"name\":\"_score\",\"type\":\"number\",\"count\":0,\"scripted\":false,\"indexed\":false,\"analyzed\":false,\"doc_values\":false,\"searchable\":false,\"aggregatable\":false}]","fieldFormatMap":"{\"@timestamp\":{\"id\":\"date\"}}"}
EOF

chmod -R a+r /kibana-index-patterns

echo "Kibana index patterns installed."