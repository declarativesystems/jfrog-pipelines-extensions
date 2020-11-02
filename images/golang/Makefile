DOCKER_REPOSITORY := docker-local/golang
DOCKER_TAG := 0.0.0-6
IMAGE_NAME := declarativesystems.jfrog.io/docker/$(DOCKER_REPOSITORY):$(DOCKER_TAG)

build:
	docker build . -t $(IMAGE_NAME)

shell: build
	docker run --rm -v $(shell pwd):/u18 -ti $(IMAGE_NAME) bash

push: build
	docker push $(IMAGE_NAME)

login:
	docker login declarativesystems.jfrog.io