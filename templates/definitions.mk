TOP_REL ?= ../..
BASE := $(TOP_REL)/BUILD/debian/$(PKG)/var/lib/libvirt/images
DEST := $(BASE)/virl-base-images
NDEF := $(BASE)/node-definitions
TAG  := $(shell echo $(VERSION) | tr '[:upper:]~.+:' '[:lower:]----')
NTAG := $(NAME)-$(TAG)
DNT  := $(DEST)/$(NTAG)

.PHONY: definitions
definitions: $(DNT) $(NDEF)
	@if [ -f ./.disabled ]; then \
		echo "Skipping definitions in $(CURDIR): .disabled present"; \
	else \
		sha256=$$(docker image inspect -f '{{ index .Id }}' $(NAME):$(TAG) 2>/dev/null | cut -d':' -f2) || sha256=""; \
		if [ -z "$$sha256" ]; then \
			echo "Image $(NAME):$(TAG) not found; skipping definitions"; \
		else \
			date=$$(date +"%Y-%m-%d") && \
			cat $(TOP_REL)/templates/image-definition.tmpl | sed \
				-e 's/{{DESC}}/$(DESC)/g' \
				-e 's/{{FULLDESC}}/$(FULLDESC)/g' \
				-e 's/{{NAME}}/$(NAME)/g' \
				-e 's/{{VERSION}}/$(VERSION)/g' \
				-e 's/{{TAG}}/$(TAG)/g' \
				-e 's/{{NTAG}}/$(NTAG)/g' \
				-e "s/{{SHA256}}/$$sha256/g" \
				-e "s/{{DATE}}/$$date/" \
			>$(DNT)/$(NTAG).yaml && \
			cat node-definition | sed \
				-e 's/{{NAME}}/$(NAME)/g' \
				-e 's/{{DESC}}/$(DESC)/g' \
				-e 's/{{FULLDESC}}/$(FULLDESC)/g' \
				-e 's/{{VERSION}}/$(VERSION)/g' \
				-e "s/{{DATE}}/$$date/" \
				-Ee 's#("image": )"\{\{IMAGENAMETAG\}\}"#\1"$(NAME):$(TAG)"#g' \
			>$(NDEF)/$(NAME).yaml; \
		fi; \
	fi

$(DNT):
	mkdir -p $@

$(NDEF):
	mkdir -p $@
