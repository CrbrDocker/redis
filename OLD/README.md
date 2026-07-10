#* Redis

## Build
Note : depend de buildx (cross platform build) & la VM de base Debian Bookworm.

*** Les fichiers
- DockerFileRedis : le dockerfile... pour lancer le build
- install-redis.sh : fichier d'install de l'image. Il est copie et execute dans l'image pendant le build
- ./need_rebuild.sh : script qui permet de checker les modification et rebuilder au cas ou, si il y a eu des modifications ou des packages à updater. possiblement automatisable periodiquement.

### Build : 

#### Build de test : 
```
docker build --no-cache -f DockerFileRedis -t monimagedetest .
```
... et ensuite, on peut la run

PS : penser Ã  tout cleaner prune & co avant de lancer le build final.


#### Build final, pushÃ© sur le repo : 
```
docker buildx build --no-cache --platform linux/amd64,linux/arm64 -f DockerFileRedis -t crbrdocker/redis . --push
```
Attention, il faut le lancer imperativement dans le repertoire ici, sinon des problemes de path
(note, on doit le pusher avec buildx directement, sinon ca ne met pas l'image a dispo, ca la laisse juste dans le cache de build) 

#### Automatisation build : 
le script ./need_rebuild.sh peut tout faire. Il faut le lancer imperativement dans le repertoire ici, sinon des problemes de path

** Utilisation
Juste docker run ... 

Un volume : /srv/data/redis qui va contenir la base de donnée persistante de redis (si on ne donne rien au run, il est créé automatiquement).
