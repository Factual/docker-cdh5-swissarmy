FROM factual/docker-cdh5-base

ENV PG_VERSION=9.5 \
    MONGO_VERSION=3.2 \
    DOCKER_CHANNEL=stable \
    DOCKER_VERSION=17.12.0 \
    INFLUXDB_VERSION=1.2.2

VOLUME /var/lib/docker

RUN echo "== Add mongo ${MONGO_VERSION} source =>" && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927 && \
    echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/${MONGO_VERSION} multiverse" | tee /etc/apt/sources.list.d/mongodb.list && \
    \
    echo "== Add postgresql source =>" && \
    curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ "$(lsb_release -sc)"-pgdg main" >> /etc/apt/sources.list.d/pgdg.list && \
    \
    echo "== Add docker source =>" && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) \
      $DOCKER_CHANNEL" && \
    \
    echo "== Install apt packages =>" && \
    apt-get update && \
    apt-get install -y \
      sudo \
      git-core \
      postgresql-client-$PG_VERSION \
      mysql-client \
      mongodb-org-shell mongodb-org-tools \
      redis-tools \
      docker-ce=`apt-cache madison docker-ce | grep $DOCKER_VERSION | awk '{ print $3 }'` \
      && \
    \
    echo "== Install influxdb =>" && \
    curl -sL https://dl.influxdata.com/influxdb/releases/influxdb-${INFLUXDB_VERSION}_linux_amd64.tar.gz > /tmp/influxdb.tar.gz && \
    cd /tmp/ && tar xvfz /tmp/influxdb.tar.gz && \
    cp /tmp/influxdb-1.2.2-1/usr/bin/influxd /usr/local/bin/ && \
    \
    echo "== Cleanup =>" && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD scripts /root/scripts
ADD bootstrap.sh /etc/my_init.d/099_bootstrap
