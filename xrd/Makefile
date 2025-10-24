include vars.mk
include ../templates/build.mk

XRD := xrd-control-plane-container-x86.$(VERSION).tgz
TMPIMG := xrd-control-plane-container-x64.dockerv1.tgz
IMG := ios-xrd.tgz

# Override image preparation via PREPARE_IMAGE_CMD for template
PREPARE_IMAGE_CMD = \
	if ! [ -f "$(XRD)" ]; then \
	  echo "required file missing, see README"; \
	  exit 1; \
	fi; \
	tar zxvf $(XRD) ./$(TMPIMG); \
	gunzip --stdout $(TMPIMG) | docker load; \
	rm -f $(TMPIMG); \
	docker tag ios-xr/xrd-control-plane:$(VERSION) $(NAME):$(TAG)
