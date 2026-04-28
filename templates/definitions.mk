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
		tarball=$(DNT)/$(NTAG).tar.gz; \
		sha256=$$(tar xzf "$$tarball" manifest.json -O 2>/dev/null | \
			python3 -c "import json,sys;c=json.load(sys.stdin)[0]['Config'];print(c.split('/')[-1].replace('.json',''))" 2>/dev/null) || sha256=""; \
		if [ -z "$$sha256" ]; then \
			echo "Tarball $$tarball not found or has no manifest; skipping definitions"; \
		else \
			date=$$(date +"%Y-%m-%d") && \
			cat $(TOP_REL)/templates/image-definition.tmpl | sed \
				-e 's/{{DESC}}/$(DESC)/g' \
				-e 's/{{FULLDESC}}/$(FULLDESC)/g' \
				-e 's/{{NAME}}/$(NAME)/g' \
				-e 's/{{TAG}}/$(TAG)/g' \
				-e 's/{{NTAG}}/$(NTAG)/g' \
				-e "s/{{SHA256}}/$$sha256/g" \
				-e "s/{{DATE}}/$$date/" \
			>$(DNT)/$(NTAG).yaml && \
			cat node-definition | sed \
				-e 's/{{NAME}}/$(NAME)/g' \
				-e 's/{{DESC}}/$(DESC)/g' \
				-e "s/{{DATE}}/$$date/" \
			>$(NDEF)/$(NAME).yaml; \
		fi; \
	fi

$(DNT):
	mkdir -p $@

$(NDEF):
	mkdir -p $@
