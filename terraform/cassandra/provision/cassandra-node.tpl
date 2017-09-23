#!/bin/bash
set -e

export CASSANDRA_HOST=`ifconfig eth0 | grep "inet " | awk '{ print substr($2,6) }'`

sudo service cassandra stop

#sudo cat <<EOF >/tmp/cloudwatch.cfg
#[general]
#state_file = /var/awslogs/state/agent-state
#
#[consul]
#file = ${consul_log_file}
#log_group_name = ${log_group_name}
#log_stream_name = ${log_stream_name}-consul
#datetime_format = %b %d %H:%M:%S
#EOF

# Configure the consul agent
cat <<EOF >/tmp/consul.json
{
  "addresses": {
    "http": "0.0.0.0"
  },
  "disable_anonymous_signature": true,
  "disable_update_check": true,
  "datacenter": "terraform",
  "data_dir": "/mnt/consul",
  "log_level": "TRACE",
  "retry_join": ["consul.internal"],
  "enable_script_checks": true,
  "leave_on_terminate": true
}
EOF
sudo mv /tmp/consul.json /etc/consul.d/consul.json

sudo cat <<EOF >/tmp/consul.service
[Unit]
Description=Consul service discovery agent
Requires=network-online.target
After=network.target

[Service]
User=ubuntu
Group=ubuntu
PIDFile=/var/consul/consul.pid
Restart=on-failure
Environment=GOMAXPROCS=2
ExecStartPre=/bin/rm -f /var/consul/consul.pid
ExecStartPre=/usr/local/bin/consul configtest -config-dir=/etc/consul.d
ExecStart=/usr/local/bin/consul agent -pid-file=/var/consul/consul.pid -config-dir=/etc/consul.d -bind="CASSANDRA_HOST" -node="cassandra-CASSANDRA_HOST" >>${consul_log_file} 2>&1
ExecReload=/bin/kill -s HUP
KillSignal=SIGINT
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo sed -i -e 's/CASSANDRA_HOST/'$CASSANDRA_HOST'/g' /tmp/consul.service
sudo mv /tmp/consul.service /etc/systemd/system/consul.service

# Configure the cassandra healthchecks
sudo cat <<EOF >/tmp/cassandra.json
{
    "services": [{
        "name": "cassandra",
        "tags": [
            "telnet", "cassandra"
        ],
        "port": 7000,
        "checks": [{
            "id": "1",
            "name": "cassandra TCP",
            "notes": "Use nodetool to check the service every 60 seconds",
            "script": "nodetool status >/dev/null 2>&1",
            "interval": "60s"
        } ],
        "leave_on_terminate": true
    }]
}
EOF
sudo mv /tmp/cassandra.json /etc/consul.d/cassandra.json

sudo cat <<EOF >/tmp/filebeat.yml
filebeat:
  prospectors:
    -
      paths:
        - /var/log/auth.log
        - /var/log/syslog
        - /var/log/cassandra/system.log

      input_type: log

      document_type: syslog

  registry_file: /var/lib/filebeat/registry

output:
  logstash:
    hosts: ["logstash.${hosted_zone_name}:5044"]
    bulk_max_size: 1024
    ssl.enabled: false

shipper:

logging:
  files:
    rotateeverybytes: 10485760 # = 10MB
EOF
sudo mv /tmp/filebeat.yml /etc/filebeat/filebeat.yml
sudo chown root.root /etc/filebeat/filebeat.yml
sudo chmod go-w /etc/filebeat/filebeat.yml

sudo update-rc.d filebeat defaults 95 10
sudo service filebeat start

sudo cat <<EOF >/tmp/cassandra.yaml
# Cassandra storage config YAML
cluster_name: 'CassandraCluster'
num_tokens: 256
hinted_handoff_enabled: true
max_hint_window_in_ms: 10800000 # 3 hours
hinted_handoff_throttle_in_kb: 1024
max_hints_delivery_threads: 2
hints_flush_period_in_ms: 10000
max_hints_file_size_in_mb: 128
batchlog_replay_throttle_in_kb: 1024
authenticator: AllowAllAuthenticator
authorizer: AllowAllAuthorizer
role_manager: CassandraRoleManager
roles_validity_in_ms: 2000
permissions_validity_in_ms: 2000
credentials_validity_in_ms: 2000
partitioner: org.apache.cassandra.dht.Murmur3Partitioner
data_file_directories:
    - /var/lib/cassandra/data
commitlog_directory: /var/lib/cassandra/commitlog
cdc_enabled: false
disk_failure_policy: stop
commit_failure_policy: stop
prepared_statements_cache_size_mb:
thrift_prepared_statements_cache_size_mb:
key_cache_size_in_mb:
key_cache_save_period: 14400
row_cache_size_in_mb: 0
row_cache_save_period: 0
counter_cache_size_in_mb:
counter_cache_save_period: 7200
saved_caches_directory: /var/lib/cassandra/saved_caches
commitlog_sync: periodic
commitlog_sync_period_in_ms: 10000
commitlog_segment_size_in_mb: 32
seed_provider:
    - class_name: org.apache.cassandra.locator.SimpleSeedProvider
      parameters:
          - seeds: "${cassandra_seeds}"
concurrent_reads: 32
concurrent_writes: 32
concurrent_counter_writes: 32
concurrent_materialized_view_writes: 32
memtable_allocation_type: heap_buffers
index_summary_capacity_in_mb:
index_summary_resize_interval_in_minutes: 60
trickle_fsync: false
trickle_fsync_interval_in_kb: 10240
storage_port: 7000
ssl_storage_port: 7001
listen_address: CASSANDRA_HOST
start_rpc: false
rpc_address: CASSANDRA_HOST
rpc_port: 9160
rpc_keepalive: true
rpc_server_type: sync
thrift_framed_transport_size_in_mb: 15
incremental_backups: false
snapshot_before_compaction: false
auto_snapshot: true
column_index_size_in_kb: 64
column_index_cache_size_in_kb: 2
compaction_throughput_mb_per_sec: 16
sstable_preemptive_open_interval_in_mb: 50
request_timeout_in_ms: 10000
cross_node_timeout: false
endpoint_snitch: Ec2Snitch
dynamic_snitch_update_interval_in_ms: 100
dynamic_snitch_reset_interval_in_ms: 600000
dynamic_snitch_badness_threshold: 0.1
request_scheduler: org.apache.cassandra.scheduler.NoScheduler
server_encryption_options:
    internode_encryption: none
    keystore: conf/.keystore
    keystore_password: cassandra
    truststore: conf/.truststore
    truststore_password: cassandra
client_encryption_options:
    enabled: false
    optional: false
    keystore: conf/.keystore
    keystore_password: cassandra
internode_compression: dc
inter_dc_tcp_nodelay: false
tracetype_query_ttl: 86400
tracetype_repair_ttl: 604800
enable_user_defined_functions: false
enable_scripted_user_defined_functions: false
windows_timer_interval: 1
transparent_data_encryption_options:
    enabled: false
    chunk_length_kb: 64
    cipher: AES/CBC/PKCS5Padding
    key_alias: testing:1
    key_provider:
      - class_name: org.apache.cassandra.security.JKSKeyProvider
        parameters:
          - keystore: conf/.keystore
            keystore_password: cassandra
            store_type: JCEKS
            key_password: cassandra
tombstone_warn_threshold: 1000
tombstone_failure_threshold: 100000
batch_size_warn_threshold_in_kb: 5
batch_size_fail_threshold_in_kb: 50
unlogged_batch_across_partitions_warn_threshold: 10
compaction_large_partition_warning_threshold_mb: 100
gc_warn_threshold_in_ms: 1000
auto_bootstrap: true
EOF
sudo sed -i -e 's/CASSANDRA_HOST/'$CASSANDRA_HOST'/g' /tmp/cassandra.yaml
sudo mv /tmp/cassandra.yaml /etc/cassandra/cassandra.yaml

sudo cat <<EOF >/tmp/cassandra-rackdc.properties
dc=DC1
rack=RAC1
EOF
sudo mv /tmp/cassandra-rackdc.properties /etc/cassandra/cassandra-rackdc.properties

sudo sed -i 's/127.0.0.1 .*$/127.0.0.1 localhost '$(hostname)'/g' /etc/hosts

sudo service cassandra start

sudo service consul start

#sudo /usr/bin/awslogs-agent-setup.py -n -r ${aws_region} -c /tmp/cloudwatch.cfg
#sudo update-rc.d awslogs defaults 95 10
#sudo service awslogs start
#sudo systemctl daemon-reload

sleep 60

sudo nodetool status

echo "Done"
