# For Ubuntu 18
FROM ubuntu:noble

LABEL name="zookeeper" version="3.4.13"

# Install required software
RUN apt-get update && apt-get install -y software-properties-common jq wget curl gnupg2

# Setup the openjdk 8 repo
RUN add-apt-repository ppa:openjdk-r/ppa

# Install java8
RUN apt-get update && apt-get install -y openjdk-8-jdk

# Setup JAVA_HOME, this is useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

RUN export JAVA_HOME

RUN wget -q -O - https://archive.apache.org/dist/zookeeper/zookeeper-3.4.13/zookeeper-3.4.13.tar.gz | tar -xzf - -C /opt \
  && mv /opt/zookeeper-3.4.13 /opt/zookeeper \
  && cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg \
  && mkdir -p /tmp/zookeeper

# Copy over zk-tool and script.sh
COPY zk-tool /opt/zookeeper/
COPY script.sh /opt/zookeeper/

# Install ruby using RVM
# Install RVM first
RUN /bin/bash -xc \
  'for server in \
    ha.pool.sks-keyservers.net \
    hkp://keyserver.ubuntu.com:80 \
    hkp://p80.pool.sks-keyservers.net:80 \
    pgp.mit.edu \
  ; do \
    gpg2 --keyserver "$server" --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB; \
  done; \
  curl -sSL https://get.rvm.io | bash -s stable \
  && source /etc/profile.d/rvm.sh \
  && rvm install 2.6.0 \
  && rvm use 2.6.0 --default'

ENV RVM_HOME /usr/local/rvm
ENV RUBY_HOME /usr/local/rvm/rubies/ruby-2.6.0
ENV PATH $PATH:$RVM_HOME/bin:$RUBY_HOME/bin

# Install the ruby gems required for zk-tool
RUN gem install thor \
  && gem install zk

EXPOSE 2181 2888 3888
WORKDIR /opt/zookeeper

VOLUME ["/opt/zookeeper/conf", "/tmp/zookeeper"]
ENTRYPOINT ["/opt/zookeeper/bin/zkServer.sh"]
CMD ["start-foreground"]
