.PHONY: all
all: build definitions

# the name of our package
PKG := refplat-images-docker
export PKG

include vars.mk
include ../templates/definitions.mk
include ../templates/clean.mk

XRD := xrd-control-plane-container-x86.$(VERSION).tgz
TMPIMG := xrd-control-plane-container-x64.dockerv1.tgz
IMG := ios-xrd.tgz

.PHONY: build
build: $(DNT)/$(NTAG).tar.gz

$(DNT)/$(NTAG).tar.gz: Dockerfile | $(DNT)
	@if ! [ -f "$(XRD)" ]; then \
	  echo "required file missing, see README"; \
		exit 1; \
	fi
	tar zxvf $(XRD) ./$(TMPIMG)
	gunzip --stdout $(TMPIMG) | docker load
	rm -f $(TMPIMG)

	docker tag  ios-xr/xrd-control-plane:$(VERSION) $(NAME):$(TAG)
	docker save $(NAME):$(TAG) | gzip - >$(IMG)

	mv -f $(IMG) $(DNT)/$(NTAG).tar.gz
