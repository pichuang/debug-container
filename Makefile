IMAGE_REPO=localhost
IMAGE_NAME=debug-container
IMAGE_TAG=20190804
CONTAINER_NAME=debug-container

build-buildah: # Build the container with Buildah
	buildah bud -t $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) .
	buildah images

run-buildah: # Run OCI Image
	buildah run --rm -it --name $(CONTAINER_NAME) $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

build-docker: # Build the container with Docker
	docker build -t $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) .
	docker images

run-docker: # Run Docker Image
	docker run --rm -it --name $(CONTAINER_NAME) $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

