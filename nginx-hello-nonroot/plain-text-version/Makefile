VERSION=0.1
PREFIX=nginxdemos/nginx-hello
TAG=$(VERSION)

all: build push test

build:
	docker build -t PREFIX:TAG .
push:
	docker push PREFIX:TAG
test:
	docker run -d -p 8080 --name nginx-hello PREFIX:TAG