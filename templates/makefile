.PHONY: all
all: build

include vars.mk
include ../templates/definitions.mk

.PHONY: clean
clean:
	rm -rf $(DNT)
	-docker image ls --format "{{ .ID }}" $(NAME) | uniq | xargs docker image rm -f

.PHONY: docker
docker: Dockerfile $(DNT)
	docker buildx build . -t $(NAME):$(TAG) --build-arg uid=2000 --build-arg version=$(VERSION)
	docker save $(NAME):$(TAG) | gzip - >$(DNT)/$(NTAG).img.gz

.PHONY: build
build: docker definitions
	@echo "## done"

