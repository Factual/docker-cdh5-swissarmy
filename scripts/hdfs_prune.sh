#!/bin/bash

## prunes all but newest RETAIN_FILES (count) matching FILE_PATTERN
## useful for rotating backup files

#defaults

RETAIN_FILES=${RETAIN_FILES:-5}

if [ -n $FILE_PATTERN ]; then
  (hdfs dfs -ls $FILE_PATTERN | sort -rk6 | head -n $RETAIN_FILES | sed 's/  */ /g' | cut -d\  -f8 ; hdfs dfs -ls $FILE_PATTERN | sed 's/  */ /g' | cut -d\  -f8 ) | sort | uniq -u | sed -e 's,.*,"&",g' | xargs -I FILE bash -c 'echo "Deleting: FILE"; hdfs dfs -rm FILE'
else
  echo "You need to set a FILE_PATTERN"
  exit 1
fi
