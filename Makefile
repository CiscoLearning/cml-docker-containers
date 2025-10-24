# list of subdirectories containing a Dockerfile (skip dirs with .disabled)
SUBDIRS := $(shell find . -type f -name Dockerfile -exec dirname {} \; | sort -u | while read -r d; do if [ ! -f "$$d/.disabled" ]; then echo "$$d"; fi; done)

# timestamp for ISO naming; can be overridden via make iso TS=...
TS ?= $(shell date -u +%Y%m%d%H%M%S)
 
.PHONY: build $(SUBDIRS)
build: $(SUBDIRS)
 
$(SUBDIRS):
	$(MAKE) -C $@
 
.PHONY: clean
clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done
	@rm -rf debian/refplat-images-docker
	@cd BUILD && ( command -v dh_clean >/dev/null 2>&1 && dh_clean || true )

.PHONY: iso
iso: build
	@set -e; \
	images_dir="BUILD/debian/refplat-images-docker/var/lib/libvirt/images"; \
	[ -d "$$images_dir" ] || { echo "Images dir not found: $$images_dir"; exit 1; }; \
	out_iso="docker-refplat-images-$(TS).iso"; \
	echo "Creating $$out_iso from $$images_dir/node-definitions and $$images_dir/virl-base-images"; \
	xorriso -as mkisofs -V REFPLAT -r -J -o "$$out_iso" "$$images_dir"; \
	ls -lh "$$out_iso"
 
 
.PHONY: deb
deb: build
	cd BUILD && dpkg-buildpackage --build=binary --no-sign --no-check-builddeps
 
.PHONY: definitions
definitions:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir definitions; \
	done

