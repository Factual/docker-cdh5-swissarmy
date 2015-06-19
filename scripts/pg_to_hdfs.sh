#!/bin/bash

function stream_backup_to_hdfs() {
  
  n=1
  until [ $n -gt $MAX_RETRIES ]
  do
    echo "Start dump $1: [Attempt $n of $MAX_RETRIES]"
    pg_dump -U $PG_USER -h $PG_HOST -p $PG_PORT -d $1 | gzip | hdfs dfs -put -f - $CURRENT_BACKUP_FOLDER/$1.gz && echo "Finished dump: $1 [Attempt $n of $MAX_RETRIES]" && return 0  
    
    echo "Failed dump: $1"
    n=$[$n+1]
    sleep 1
  done
  echo "Exceeded retries: $1"
  exit 1
}

function list_old_folders() {
  (hdfs dfs -ls -d $BACKUP_PATH/????-* | sort -rk6 | head -n $RETAIN_VERSIONS | sed 's/  */ /g' | cut -d\  -f8 ; hdfs dfs -ls $BACKUP_PATH | sed 's/  */ /g' | cut -d\  -f8 ) | sort | uniq -u | sed -e 's,.*,&,g'
}

function prune_folder(){
   echo "Deleting: $1"
   hdfs dfs -rm -r $1
}

DATE=`date +%Y-%m-%d_%H_%M_%S`
RETAIN_VERSIONS=${RETAIN_VERSIONS:-5}
MAX_RETRIES=${MAX_RETRIES:-5}
PG_PORT=${PG_PORT:-5432}

if [ -z $PG_USER ]; then
  echo "You need to set PG_USER"
  exit 1
fi

if [ -z $PG_DB ]; then
  echo "You need to set PG_DB"
  exit 1
fi

if [ -z $PG_HOST ]; then
  echo "You need to set PG_HOST"
  exit 1
fi

if [ -z $BACKUP_PATH ]; then
  echo "You need to set BACKUP_PATH"
  exit 1
fi

#first create the backup folder where we will stream the files
CURRENT_BACKUP_FOLDER=$BACKUP_PATH/$DATE
hdfs dfs -mkdir -p $CURRENT_BACKUP_FOLDER

#now loop over the databas(es) and stream them to hdfs
for db in ${PG_DB//,/ }; do
  stream_backup_to_hdfs $db
done

#finally prune all but the last RETAIN_VERSIONS folders
for fol in $(list_old_folders); do
  [ -n $fol ] && [[ $fol == "$BACKUP_PATH"* ]] && prune_folder $fol
done

