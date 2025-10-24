.PHONY: all
all: build

# the name of our package
PKG := refplat-images-docker
export PKG

HTTP_PROXY=
HTTPS_PROXY=
NO_PROXY=

include vars.mk
include ../templates/definitions.mk
include ../templates/clean.mk

.PHONY: docker
# Build image only if tarball is missing or older than Dockerfile; otherwise load cached tarball
docker: $(DNT)/$(NTAG).tar.gz

$(DNT)/$(NTAG).tar.gz: Dockerfile | $(DNT)
	@if [ -f ./.disabled ]; then \
		echo "Skipping build in $(CURDIR): .disabled present"; \
	else \
		echo "Building $(NAME):$(TAG) (Dockerfile changed or cache missing)"; \
		docker buildx build . -t $(NAME):$(TAG) \
			--platform linux/amd64 \
			--load \
			--build-arg uid=2000 \
			--build-arg version=$(VERSION) \
			$(if $(HTTP_PROXY), --build-arg HTTP_PROXY=$(HTTP_PROXY)) \
			$(if $(HTTPS_PROXY), --build-arg HTTPS_PROXY=$(HTTPS_PROXY)) \
			$(if $(NO_PROXY), --build-arg NO_PROXY=$(NO_PROXY)); \
		docker save $(NAME):$(TAG) | gzip - > "$@"; \
	fi

.PHONY: build
build: docker definitions
	@echo "## done"

