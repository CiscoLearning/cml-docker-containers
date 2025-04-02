BASE := ../BUILD/refplat-images-docker_all/var/lib/libvirt/images
DEST := $(BASE)/virl-base-images
NDEF := $(BASE)/node-definitions
TAG  := $(shell echo $(VERSION) | tr '[:upper:]~' '[:lower:]-')
NTAG := $(NAME)-$(TAG)
DNT  := $(DEST)/$(NTAG)

.PHONY: definitions
definitions: $(DNT)
	sha256=`docker image inspect -f '{{ index .Id }}' $(IMAGENAMETAG) | cut -d':' -f2)` && \
  date=`date +"%Y%m%d"` && \
	cat ../templates/image-definition | sed \
		-e 's/{{DESCR}}/$(DESCR)/g' \
		-e 's/{{NAME}}/$(NAME)/g' \
		-e 's/{{VERSION}}/$(VERSION)/g' \
		-e 's/{{TAG}}/$(TAG)/g' \
		-e 's/{{NTAG}}/$(NTAG)/g' \
		-e "s/{{SHA256}}/$$sha256/g" \
	  -e "s/{{DATE}}/$$date/" \
	>$(DNT)/$(NTAG).yaml
	cat node-definition | sed \
		-re 's#("image": )"\{\{IMAGENAMETAG\}\}"#\1"$(IMAGENAMETAG)"#g' \
	> $(NDEF)/$(NAME).yaml

$(DNT):
	mkdir -p $@
