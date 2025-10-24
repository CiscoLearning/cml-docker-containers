.PHONY: all
all: build definitions

# the name of our package
PKG := refplat-images-docker
export PKG

include vars.mk
include ../templates/definitions.mk
include ../templates/clean.mk

IMG := te-ea.tgz

.PHONY: build
build: $(DNT)/$(NTAG).tar.gz

$(DNT)/$(NTAG).tar.gz: Dockerfile | $(DNT)
	docker pull thousandeyes/enterprise-agent:latest-agent
	docker tag  thousandeyes/enterprise-agent:latest-agent $(NAME):$(TAG)
	docker save $(NAME):$(TAG) | gzip - >$(IMG)
	mv -f $(IMG) $(DNT)/$(NTAG).tar.gz
