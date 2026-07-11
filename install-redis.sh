#! /bin/bash
#
# Script to install an redis




# APT

# env var so APT knows we won't answer any of its prompts
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
apt -y update
apt-get -y dist-upgrade
apt-get -y install --no-install-recommends redis-server redis-tools



# Redis config (we just create the directories, they can all be empty)
# Note: logs go to stdout (logfile "" below), so there is no log directory.
mkdir -p /srv/data
mv /srv/data/redis /srv/data && ln -s /srv/data/redis /var/lib && rm -rf /srv/data/redis/* 2>/dev/null


cat > /etc/redis/redis.conf <<'EOF'
protected-mode no
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 0
daemonize no
supervised no
pidfile /var/run/redis/redis-server.pid
loglevel warning
logfile ""
databases 16
stop-writes-on-bgsave-error no
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /srv/data/redis
slave-serve-stale-data yes
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
slave-priority 100
maxmemory 2gb
maxmemory-policy volatile-lru
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 20
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
aof-rewrite-incremental-fsync yes

EOF


# launch script
cat > /usr/local/bin/crbr-redis-start.sh <<'EOF'
#!/bin/bash

# Create them if they don't exist
mkdir -p /srv/data/redis 2>/dev/null || true
chown redis:redis /srv/data/redis
# Note: fine if empty, Redis creates its own files.

# Open-files limit
ulimit -n 65535

# Memory tweak for redis (note: the container must be run with --privileged)
sysctl -w vm.overcommit_memory=1 2> /dev/null || true

exec redis-server /etc/redis/redis.conf

EOF
chmod 755 /usr/local/bin/crbr-redis-start.sh

# APT cache cleanup
apt-get clean
apt-get autoclean

# Clean APT lists (~90 MB) and the archive cache (likewise)
# An apt-get update will be needed before next use
rm -rf /var/lib/apt/lists/* 2>/dev/null
rm -rf /var/cache/apt/*pkgcache.bin 2>/dev/null


# Clean junk before sealing the image
rm -rf /tmp/* /var/tmp/* 2> /dev/null
find /var/log -type f -delete 2> /dev/null
