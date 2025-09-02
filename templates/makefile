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

.PHONY: clean
clean:
	rm -rf $(DNT)
	-docker image ls --format "{{ .ID }}" $(NAME) | uniq | xargs docker image rm -f

.PHONY: docker
docker: Dockerfile $(DNT)
	docker buildx build . -t $(NAME):$(TAG) \
	--build-arg uid=2000 \
	--build-arg version=$(VERSION) \
	$(if $(HTTP_PROXY), --build-arg HTTP_PROXY=$(HTTP_PROXY)) \
	$(if $(HTTPS_PROXY), --build-arg HTTPS_PROXY=$(HTTPS_PROXY)) \
	$(if $(NO_PROXY), --build-arg NO_PROXY=$(NO_PROXY))
	docker save $(NAME):$(TAG) | gzip - >$(DNT)/$(NTAG).tar.gz

.PHONY: build
build: docker definitions
	@echo "## done"

