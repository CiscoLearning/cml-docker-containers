# list of subdirectories containing a Dockerfile (skip dirs with .disabled)
SUBDIRS := $(shell find . -type f -name Dockerfile -exec dirname {} \; | sort -u | while read -r d; do if [ ! -f "$$d/.disabled" ]; then echo "$$d"; fi; done)

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for dir in $(SUBDIRS); do \
			$(MAKE) -C $$dir clean; \
	done
	rm -rf debian/refplat-images-docker
	cd BUILD && dh_clean

.PHONY: all build clean $(SUBDIRS)

deb:
	cd BUILD && dpkg-buildpackage --build=binary --no-sign --no-check-builddeps

definitions:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir definitions; \
	done
