FROM factual/docker-cdh5-base

RUN apt-get install -y postgresql-client mysql-client mongodb-clients redis-tools krb5-user

ADD bootstrap.sh /etc/my_init.d/099_bootstrap