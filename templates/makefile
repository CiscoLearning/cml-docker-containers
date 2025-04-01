.PHONY: all
all: build definitions

include vars.mk
include ../templates/definitions.mk

.PHONY: clean
clean:
	rm -rf $(DNT)
	-docker image ls --format "{{ .ID }}" $(NAME) | uniq | xargs docker image rm -f

.PHONY: build
build: Dockerfile $(DNT)
	docker buildx build . -t $(NAME) --build-arg uid=2000 --build-arg version=$(VERSION)
	# docker tag $(NAME):latest $(NTAG)
	docker tag $(NAME):latest $(NAME):$(TAG)
	docker save $(NAME):latest | gzip - >$(DNT)/$(NTAG).img.gz

