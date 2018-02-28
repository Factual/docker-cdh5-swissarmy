#!/bin/bash

[ $DEBUG ] && set -x

if [ -z $REDIS_HOST ]; then
  echo "You need to set REDIS_HOST"
  exit 1
fi

if [ -z $BACKUP_PATH ]; then
  echo "You need to set BACKUP_PATH"
  exit 1
fi

DATE=`date +%Y-%m-%d_%H_%M_%S`
RETAIN_VERSIONS=${RETAIN_VERSIONS:-5}
MAX_RETRIES=${MAX_RETRIES:-5}
REDIS_PORT=${REDIS_PORT:-5432}
CURRENT_BACKUP_FOLDER=$BACKUP_PATH/$DATE
REDIS_DOCKER_IMAGE=${REDIS_DOCKER_IMAGE:-redis:4}
REDIS_SYNC_TIMEOUT=${REDIS_SYNC_TIMEOUT:-60}

service docker start
# tail -f /var/log/docker.log &

hdfs dfs -mkdir -p $CURRENT_BACKUP_FOLDER

function list_old_folders() {
  (hdfs dfs -ls -d $BACKUP_PATH/????-* | sort -rk6 | head -n $RETAIN_VERSIONS | sed 's/  */ /g' | cut -d\  -f8 ; hdfs dfs -ls $BACKUP_PATH | sed 's/  */ /g' | cut -d\  -f8 ) | sort | uniq -u | sed -e 's,.*,&,g'
}

function prune_folder() {
   echo "Deleting: $1"
   hdfs dfs -rm -r $1
}

function backup_to_hdfs() {
  n=1
  until [ $n -gt $MAX_RETRIES ]; do
    echo "Start dump: [Attempt $n of $MAX_RETRIES]"

    rm -rf data && \
    mkdir -p data && \
    \
    docker rm -f redis || echo "NO RUNNING REDIS" && \
    docker rm -f redis_cli || echo "NO RUNNING REDIS_CLI" && \
    \
    docker run --name redis --network host --detach --rm --volume $(pwd)/data:/data ${REDIS_DOCKER_IMAGE} redis-server --appendonly yes && \
    docker run --name redis_cli --network host --rm ${REDIS_DOCKER_IMAGE} bash -c "
      redis-cli SLAVEOF "$REDIS_HOST" "$REDIS_PORT"
      echo
      echo '====== Redis sync process started ======'
      REDIS_SYNC_WAIT_TIME=${REDIS_SYNC_TIMEOUT}
      while [ ! \"\`redis-cli INFO replication | grep 'master_link_status:up'\`\" ]; do
        (( \$REDIS_SYNC_WAIT_TIME <= 0 )) && exit 1
        (( REDIS_SYNC_WAIT_TIME-- ))
        echo '====== Waiting redis sync data from master ======'
        sleep 1
      done
      echo '====== Redis has been fully synced ======'
      echo
      redis-cli SLAVEOF NO ONE
      redis-cli SAVE
    " && \
    tar czf data.tar.gz data &&
    hdfs dfs -put -f data.tar.gz $CURRENT_BACKUP_FOLDER/ && echo "Finished dump: [Attempt $n of $MAX_RETRIES]" && return 0

    echo "Failed dump"
    n=$[$n+1]
    sleep 1
  done
  echo "Exceeded retries"
  exit 1
}

backup_to_hdfs

#finally prune all but the last RETAIN_VERSIONS folders
for fol in $(list_old_folders); do
  [ -n $fol ] && [[ $fol == "$BACKUP_PATH"* ]] && prune_folder $fol
done
