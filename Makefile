IMAGE_REPO=localhost
IMAGE_NAME=debug-container
IMAGE_TAG=20191220
CONTAINER_NAME=debug-container

.DEFAULT_GOAL:=help
SHELL:=/bin/bash

.PHONY: help build-buildah run-podman run-podman-mix build-docker run-docker run-docker-mix inspect-podman inspect-docker

help: ## Display help information
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build-buildah: ## Build OCI image with Buildah
	buildah bud -t $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) .
	buildah images

run-podman: ## Run Independent OCI Image
	podman run --rm -it --name $(CONTAINER_NAME) $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

run-podman-mix: ## Run Mixed OCI Image
	podman run -it --rm --name $(CONTAINER_NAME) --privileged \
       --ipc=host --net=host --pid=host -e HOST=/host \
       -e NAME=$(CONTAINER_NAME) -e IMAGE=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) \
       -v /run:/run -v /var/log:/var/log \
       -v /etc/localtime:/etc/localtime -v /:/host \
       $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

build-docker: ## Build Docker image with Docker
	docker build -t $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) .
	docker images

run-docker: ## Run Independent Docker Image
	docker run --rm -it --name $(CONTAINER_NAME) $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

run-docker-mix: ## Run Mixed Docker Image
	docker run -it --rm --name $(CONTAINER_NAME) --privileged \
       --ipc=host --net=host --pid=host -e HOST=/host \
       -e NAME=$(CONTAINER_NAME) -e IMAGE=$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) \
       -v /run:/run -v /var/log:/var/log \
       -v /etc/localtime:/etc/localtime -v /:/host \
       $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

inspect-podman: ## Inspect container OCI image
       skopeo inspect containers-storage:$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

inspect-docker: ## Inspect container docker image
       skopeo inspect docker://$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
