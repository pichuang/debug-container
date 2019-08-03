IMAGE_REPO=localhost
IMAGE_NAME=debug-container
IMAGE_TAG=20190804
CONTAINER_NAME=debug-container

help:  ## Display help information
                @awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build-buildah: # Build OCI container with Buildah
	buildah bud -t $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) .
	buildah images

run-podman: # Run OCI Image
	podman run --rm -it --name $(CONTAINER_NAME) $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

build-docker: # Build the container with Docker
	docker build -t $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) .
	docker images

run-docker: # Run Docker Image
	docker run --rm -it --name $(CONTAINER_NAME) $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

