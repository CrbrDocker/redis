#! /bin/bash
#
# Script to install an redis





# APT

# env var pour que APT sache qu'on ne va pas lui répondre
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
apt -y update
apt-get -y dist-upgrade
apt-get -y install --no-install-recommends redis-server redis-tools



# Conf redis (on crée juste les repertoires, tout peut être vide)
mkdir -p /srv/data /srv/log
mv /var/log/redis /srv/log && ln -s /srv/log/redis /var/log && rm -rf /srv/log/redis/* 2>/dev/null
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
logfile /var/log/redis/redis-server.log
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


# script de lancement
cat > /usr/local/bin/crbr-redis-start.sh <<'EOF'
#!/bin/bash

# On crée si ca n'existe pas
mkdir -p /srv/data/redis /srv/log/redis 2>/dev/null || true
chown redis:redis /srv/data/redis /srv/log/redis
# Note : pas grave si c'est vide, Redis crée ses fichiers.

# Clean des ancien logs
rm -rf /srv/log/redis/* 2> /dev/null || true

# Limite fichiers ouverts
ulimit -n 65535

# Truc de mémoire pour redis (note : le container doit être lancé avec --privileged
sysctl -w vm.overcommit_memory=1 2> /dev/null || true

exec redis-server /etc/redis/redis.conf

EOF
chmod 755 /usr/local/bin/crbr-redis-start.sh

# Nettoyage du cache APT 
apt-get clean
apt-get autoclean

# Nettoyage liste APT (90 Mo) et cache archives (idem)
# Il faudra faire un apt-get update avant prochain usage
rm -rf /var/lib/apt/lists/* 2>/dev/null
rm -rf /var/cache/apt/*pkgcache.bin 2>/dev/null


# Clean des conneries avant de clore l'image
rm -rf /tmp/* /var/tmp/* 2> /dev/null
find /var/log -type f -delete 2> /dev/null

