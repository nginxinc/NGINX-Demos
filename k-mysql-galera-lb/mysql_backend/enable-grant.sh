#!/bin/bash
# Login into the mysql containers and change GRANT privilege to access mysql remotely
for i in `seq 1 2`; do
        docker exec -ti mysqld$i mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;FLUSH PRIVILEGES;"
done
