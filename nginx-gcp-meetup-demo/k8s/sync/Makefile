all: push

NAME = gcr.io/<project-id>/knsync

container:
	docker build -t $(NAME) .

push: container
	gcloud docker push $(NAME)
