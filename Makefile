# Variables
# Set the default Kubernetes version
K8S_VERSION ?= 1.26.3

# Define the Docker image name
DOCKER_IMAGE_NAME := kindest/node

# Define a suffix to identify the image with the Corporate TLS certificate
DOCKER_IMAGE_TAG_SUFFIX := with-org-ca

# Combine the Kubernetes version and the suffix to form the complete image tag
DOCKER_IMAGE_TAG := v$(K8S_VERSION)-$(DOCKER_IMAGE_TAG_SUFFIX)

CLUSTER_SCRIPTS_DIR := cluster-scripts

# Build the Docker image
# Usage: make build [K8S_VERSION=<desired_version>]
build:
	@echo "Building the Docker image with the certificate."
	@echo "Kubernetes version: $(K8S_VERSION)"
	docker build --build-arg K8S_VERSION=$(K8S_VERSION) -t $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) -f Containerfiles/Containerfile.OrgCa Containerfiles/

# Clean up the Docker image
clean-image:
	@echo "Cleaning up the Docker image: $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)"
	docker rmi $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

# Clean up all Docker images with the custom tag
clean-all-images:
	@echo "Cleaning up all Docker images with the tag: $(DOCKER_IMAGE_TAG)"
	docker images -q $(DOCKER_IMAGE_NAME) | grep $(DOCKER_IMAGE_TAG) | xargs -r docker rmi

# Run the script to bootstrap the devops-cluster
# Usage: make bootstrap-devops-cluster
bootstrap-devops-cluster:
	bash $(CLUSTER_SCRIPTS_DIR)/bootstrap-devops-cluster.sh
# Run the script to bootstrap the devops-cluster with custom image
# Usage: make bootstrap-devops-cluster-custom
bootstrap-devops-cluster-custom:
	make build
	bash $(CLUSTER_SCRIPTS_DIR)/bootstrap-devops-cluster.sh --enable-custom-image

# Tear down kind clusters
tear-down:
	bash $(CLUSTER_SCRIPTS_DIR)/tear-down-cluster.sh

# Help command to display available targets
help:
	@echo "Available targets:"
	@echo "  make build [K8S_VERSION=<desired_version>]"
	@echo "       Build the Docker image with the certificate."
	@echo "       The default Kubernetes version is $(K8S_VERSION)."
	@echo "       Example: make build K8S_VERSION=1.20.5"
	@echo "  make clean-image"
	@echo "       Clean up the Docker image that was just built."
	@echo "  make clean-all-images"
	@echo "       Clean up all Docker images with the tag: $(DOCKER_IMAGE_TAG)"
	@echo "  make bootstrap-devops-cluster"
	@echo "       Run the script to bootstrap the devops-cluster."
	@echo "  make bootstrap-devops-cluster-custom"
	@echo "       Run the script to bootstrap the devops-cluster with custom image."
	@echo "  make tear-down"
	@echo "       Tear down kind clusters."
	@echo "  make help"
	@echo "       Display available targets."
