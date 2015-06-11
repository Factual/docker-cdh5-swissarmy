# docker-cdh5-swissarmy
container with cdh5 prerequisites that will run a bootstrap script from an url (useful for things like chronos tasks)

## to make it handy for backing up stuff to hdfs, it has the following clients:

* postgresql
* mysql
* mongodb
* redis

## useful scripts in scripts folder

### hdfs_prune

useful for rotating backup files -- it prunes all but newest RETAIN_FILES (count) matching FILE_PATTERN (e.g. /user/john_doe/some_project/part-*)
