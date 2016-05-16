FROM factual/docker-cdh5-base

# for mongo 3 tools
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
RUN echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.0.list

#postgres
ENV PG_VERSION=9.5
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
RUN curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -


RUN apt-get update && apt-get install -y git-core postgresql-client-$PG_VERSION mysql-client mongodb-org-shell mongodb-org-tools redis-tools

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD scripts /root/scripts
ADD bootstrap.sh /etc/my_init.d/099_bootstrap