# list of subdirectories containing a Dockerfile (skip dirs with .disabled)
SUBDIRS := $(shell find . -type f -name Dockerfile -exec dirname {} \; | sort -u | while read -r d; do if [ ! -f "$$d/.disabled" ]; then echo "$$d"; fi; done)

# define the package name
include templates/pkg.mk
LVIMAGES := BUILD/debian/$(PKG)/var/lib/libvirt/images

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
	@rm -rf debian/$(PKG)
	@cd BUILD && ( command -v dh_clean >/dev/null 2>&1 && dh_clean || true )

.PHONY: iso iso-list clean-iso
# Split ISO build: uses per-subdir file 'iso-name' containing a suffix like "", "-extras", "-big"
# Builds one ISO per suffix group with constant volume label REFPLAT.
iso: build
	@scripts/build-split-isos.sh "$(TS)" "$(SUBDIRS)" "$(LVIMAGES)"

# Show mapping of modules to suffixes and predicted ISO names
iso-list:
	@set -e; \
	suffixes=$$(for d in $(SUBDIRS); do [ -f "$$d/iso-name" ] && cat "$$d/iso-name" || echo ""; done | tr -d '\r' | sed -E 's/[[:space:]]+$$//' | sort -u); \
	echo "Discovered suffix groups:"; \
	for sfx in $$suffixes; do echo "  group: '"$$sfx"' -> docker-refplat-images"$$sfx"-$(TS).iso"; done; \
	echo "Module assignments:"; \
	for d in $(SUBDIRS); do \
		[ -f "$$d/iso-name" ] && sfx=$$(cat "$$d/iso-name" | tr -d '\n' | sed -E 's/[[:space:]]+$$//') || sfx=""; \
		echo "  $$d -> '"$$sfx"'"; \
	done

# Clean ISO outputs and staging trees
clean-iso:
	@rm -f docker-refplat-images*-$(TS).iso; \
	rm -rf $(LVIMAGES)/iso-staging*;

 
.PHONY: deb
deb: build
	cd BUILD && dpkg-buildpackage --build=binary --no-sign --no-check-builddeps
 
.PHONY: definitions
definitions:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir definitions; \
	done

