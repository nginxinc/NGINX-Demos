all: push

NAME = gcr.io/<project-id>/autoscaler

container:
	docker build -t $(NAME) .

push: container
	gcloud docker push $(NAME)
