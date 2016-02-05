FROM ubuntu:14.04
MAINTAINER Kunal Pariani <kunal.pariani@nginx.com>
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y software-properties-common
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 BC19DDBA
RUN add-apt-repository 'deb http://releases.galeracluster.com/ubuntu trusty main'
RUN apt-get update
RUN apt-get install -y galera-3 galera-arbitrator-3 mysql-wsrep-5.6 rsync lsof
COPY my.cnf /etc/mysql/my.cnf

# install xinetd
RUN apt-get install -y xinetd

# copy over the mysql health check scripts
COPY mysqlchk /opt/mysqlchk
RUN chmod 744 /opt/mysqlchk
RUN echo "mysqlchk        9200/tcp                        # mysqlchk" >> /etc/services
COPY mysqlchk_service /etc/xinetd.d/mysqlchk

ENTRYPOINT ["mysqld"]
