.PHONY: all
all: build

# define the package name
TOP_REL ?= ../..
include $(TOP_REL)/templates/pkg.mk
export PKG

HTTP_PROXY=
HTTPS_PROXY=
NO_PROXY=

include vars.mk

# Fail on empty VERSION: docker tag $(NAME): would silently produce a broken tarball.
ifeq ($(strip $(VERSION)),)
$(error VERSION is empty for $(NAME); check vars.mk / scripts/latest.sh)
endif

include $(TOP_REL)/templates/definitions.mk
include $(TOP_REL)/templates/clean.mk

.PHONY: docker
# Build tarball with caching; allow per-module image prep via PREPARE_IMAGE_CMD
# Submodules can set PREPARE_IMAGE_CMD to override the default build commands.
docker: $(DNT)/$(NTAG).tar.gz

# Default image preparation commands
define DEFAULT_PREPARE_IMAGE
	docker buildx build . -t $(NAME):$(TAG) \
		--platform linux/amd64 \
		--output type=docker,rewrite-timestamp=true \
		--provenance=false \
		--metadata-file=metadata.json \
		--load \
		--build-arg uid=2000 \
		--build-arg version=$(VERSION) \
		$(if $(or $(HTTP_PROXY),$(HTTPS_PROXY)),--network host) \
		$(if $(HTTP_PROXY), --build-arg HTTP_PROXY=$(HTTP_PROXY)) \
		$(if $(HTTPS_PROXY), --build-arg HTTPS_PROXY=$(HTTPS_PROXY)) \
		$(if $(NO_PROXY), --build-arg NO_PROXY=$(NO_PROXY))
endef

$(DNT)/$(NTAG).tar.gz: Dockerfile | $(DNT)
	@if [ -f ./.disabled ]; then \
		echo "Skipping build in $(CURDIR): .disabled present"; \
	else \
		echo "Preparing image for $(NAME):$(TAG)"; \
		$(if $(PREPARE_IMAGE_CMD),$(PREPARE_IMAGE_CMD),$(DEFAULT_PREPARE_IMAGE)); \
		docker save $(NAME):$(TAG) | gzip - > "$@"; \
	fi

.PHONY: build
build: docker definitions
	@echo "## done"

