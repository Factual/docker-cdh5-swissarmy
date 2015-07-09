FROM factual/docker-cdh5-base

# for ruby 2.2
RUN apt-add-repository ppa:brightbox/ruby-ng

# for mongo 3 tools
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
RUN echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.0.list

RUN apt-get update && apt-get install -y git-core postgresql-client mysql-client mongodb-org-shell mongodb-org-tools redis-tools krb5-user ruby2.2


ADD scripts /root/scripts
ADD bootstrap.sh /etc/my_init.d/099_bootstrap