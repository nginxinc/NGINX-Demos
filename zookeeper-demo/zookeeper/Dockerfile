FROM ubuntu:14.04
MAINTAINER Kunal Pariani <kunal.pariani@nginx.com>

LABEL name="zookeeper" version="3.4.8"

RUN apt-get update && apt-get install -y software-properties-common wget curl bash

# Setup the openjdk 8 repo
RUN add-apt-repository ppa:openjdk-r/ppa
# Install java8
RUN apt-get update && apt-get install -y openjdk-8-jdk jq
# Setup JAVA_HOME, this is useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

RUN wget -q -O - http://apache.mirrors.pair.com/zookeeper/zookeeper-3.4.8/zookeeper-3.4.8.tar.gz | tar -xzf - -C /opt \
    && mv /opt/zookeeper-3.4.8 /opt/zookeeper \
    && cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg \
    && mkdir -p /tmp/zookeeper

# Copy over zk-tool and script.sh 
ADD zk-tool /opt/zookeeper/
ADD script.sh /opt/zookeeper/

# Install ruby using RVM
# Install RVM first
RUN /bin/bash -c "curl -sSL https://rvm.io/mpapis.asc | gpg --import - \
    && curl -L get.rvm.io | bash -s stable \
    && source /etc/profile.d/rvm.sh \
    && rvm install 2.1.4 \
    && rvm use 2.1.4 --default"

ENV RVM_HOME /usr/local/rvm
ENV RUBY_HOME /usr/local/rvm/rubies/ruby-2.1.4
ENV PATH $PATH:$RVM_HOME/bin:$RUBY_HOME/bin

# Install the ruby gems required for zk-tool
RUN gem install thor \
    && gem install zk

EXPOSE 2181 2888 3888
WORKDIR /opt/zookeeper

VOLUME ["/opt/zookeeper/conf", "/tmp/zookeeper"]
ENTRYPOINT ["/opt/zookeeper/bin/zkServer.sh"]
CMD ["start-foreground"]
