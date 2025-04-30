K8S_VERSION ?= 1.32.2
DOCKER_IMAGE_NAME := kindest/node
DOCKER_IMAGE_TAG_SUFFIX := with-org-ca
DOCKER_IMAGE_TAG := v$(K8S_VERSION)-$(DOCKER_IMAGE_TAG_SUFFIX)
PLATFORM := $(shell [ "$(shell uname -m)" = "x86_64" ] && echo linux/amd64 || echo linux/arm64)

.PHONY: build clean-image clean-all-images bootstrap bootstrap-custom tear-down help

build:
	@if docker image inspect $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) > /dev/null 2>&1; then \
		echo "[*] Image $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) already exists. Skipping build."; \
	else \
		echo "[*] Building Docker image $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)..."; \
		docker build --platform=$(PLATFORM) --build-arg K8S_VERSION=$(K8S_VERSION) \
			-t $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) -f containerfiles/Containerfile.OrgCa containerfiles/; \
	fi

clean-image:
	docker rmi $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

clean-all-images:
	docker images --format '{{.Repository}}:{{.Tag}}' | grep $(DOCKER_IMAGE_TAG) | xargs -r docker rmi

bootstrap:
	bash cluster-scripts/bootstrap-cluster.sh

bootstrap-custom: build
	bash cluster-scripts/bootstrap-cluster.sh true

tear-down:
	bash cluster-scripts/tear-down-cluster.sh

help:
	@echo "Available targets:"
	@echo "  build                  Build the Docker image with custom TLS"
	@echo "  clean-image            Remove the specific image built"
	@echo "  clean-all-images       Remove all images matching the tag"
	@echo "  bootstrap              Launch cluster setup interactively"
	@echo "  bootstrap-custom       Same as bootstrap but with custom Kind image"
	@echo "  tear-down              Delete a kind cluster by name"

