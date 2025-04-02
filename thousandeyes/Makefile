.PHONY: all
all: build definitions

include vars.mk
include ../templates/definitions.mk

.PHONY: clean
clean:
	rm -rf $(DNT)
	docker image ls --format "{{ .ID }}" $(NAME) | uniq | xargs docker image rm -f

IMG := te-ea.tgz

.PHONY: build
build: $(DNT)
	@if ! [ -f $(IMG) ]; then \
	  echo "required file missing, see README"; \
		exit 1; \
	fi
	rm -f $(DNT)/$(NTAG).img.gz
	cp $(IMG) $(DNT)/$(NTAG).img.gz
