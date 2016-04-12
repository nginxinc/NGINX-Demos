all: push

NAME = gcr.io/<project-id>/backend

container:
	docker build -t $(NAME) .

push: container
	gcloud docker push $(NAME)
