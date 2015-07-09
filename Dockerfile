FROM factual/docker-cdh5-base

RUN apt-get install -y git-core postgresql-client mysql-client mongodb-clients redis-tools krb5-user

ADD scripts /root/scripts

ADD bootstrap.sh /etc/my_init.d/099_bootstrap