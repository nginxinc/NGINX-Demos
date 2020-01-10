VERSION=0.1
PREFIX=nginxdemos/nginx-hello
TAG=$(VERSION)

all: build push

build:
	@echo "Building image:"
	docker build -t $(PREFIX):$(TAG) .
push:
	@echo "Pushing image:"
	docker push $(PREFIX):$(TAG)
test:
	@echo "Running container:"
	docker run --rm -p 8080:8080 $(PREFIX):$(TAG)
