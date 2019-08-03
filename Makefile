IMAGE_NAME=debug-container
IMAGE_TAG=20190804

help: # Show how to use
	@echo Buildah: make build-buildah
	@echo Docker: make build-docker

build-buildah: # Build the container with Buildah
	buildah bud -t $(IMAGE_NAME):$(IMAGE_TAG) .
	buildah images

build-docker: # Build the container with Docker
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .
	docker images
