#!/bin/bash

function get_mongo_collections() {
  mongo --quiet --host $MONGO_HOST $MONGO_DB --eval "rs.slaveOk();db.getCollectionNames().join('\n')"
}

function stream_collection_to_hdfs() {
  
  n=1
  until [ $n -gt $MAX_RETRIES ]
  do
    echo "Start dump: $1 [Attempt $n of $MAX_RETRIES]"
    mongodump --host $MONGO_HOST --db $MONGO_DB --collection $1 --out - | gzip | hdfs dfs -put -f - $CURRENT_BACKUP_FOLDER/$1.bson.gz && echo "Finished dump: $1 [Attempt $n of $MAX_RETRIES]" && return 0  
    
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

if [ -z $MONGO_DB ]; then
  echo "You need to set MONGO_DB"
  exit 1
fi

if [ -z $MONGO_HOST ]; then
  echo "You need to set MONGO_HOST"
  exit 1
fi

if [ -z $BACKUP_PATH ]; then
  echo "You need to set BACKUP_PATH"
  exit 1
fi

#first create the backup folder where we will stream the files
CURRENT_BACKUP_FOLDER=$BACKUP_PATH/$DATE
hdfs dfs -mkdir -p $CURRENT_BACKUP_FOLDER

#now loop over the mongo collections and stream them to hdfs
for col in $(get_mongo_collections); do
  stream_collection_to_hdfs $col
done

#finally prune all but the last RETAIN_VERSIONS folders
for fol in $(list_old_folders); do
  [ -n $fol ] && [[ $fol == "$BACKUP_PATH"* ]] && prune_folder $fol
done

