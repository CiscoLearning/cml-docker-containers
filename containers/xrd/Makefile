TOP_REL := ../..
include vars.mk
include $(TOP_REL)/templates/build.mk

DOCKER_IMAGE := ios-xrd-control-plane
DOCKER_NTAG  := $(DOCKER_IMAGE)-$(TAG)

XRD := xrd-control-plane-container-x86.$(VERSION).tgz
TMPIMG := xrd-control-plane-container-x64.dockerv1.tgz

PREPARE_IMAGE_CMD = \
	if ! [ -f "$(XRD)" ]; then \
	  echo "required file missing, see README"; \
	  exit 1; \
	fi; \
	tar zxvf $(XRD) --wildcards --no-anchored $(TMPIMG); \
	gunzip --stdout $(TMPIMG) | docker load; \
	rm -f $(TMPIMG); \
	docker tag ios-xr/xrd-control-plane:$(VERSION) $(NAME):$(TAG)

# The Docker image from Cisco is ios-xrd-control-plane but the CML node type
# is xrd (NAME=xrd).  After the standard build produces xrd-* artifacts,
# rename the tarball and patch the image definition to use the original
# Docker image name.
.PHONY: build
build: docker definitions
	@if [ ! -f ./.disabled ] && [ -f "$(DNT)/$(NTAG).tar.gz" ]; then \
		mv "$(DNT)/$(NTAG).tar.gz" "$(DNT)/$(DOCKER_NTAG).tar.gz"; \
		sed -i \
			-e 's|^docker_tag:.*|docker_tag: $(DOCKER_IMAGE):$(TAG)|' \
			-e 's|^disk_image:.*|disk_image: $(DOCKER_NTAG).tar.gz|' \
			"$(DNT)/$(NTAG).yaml"; \
	fi
	@echo "## done"
