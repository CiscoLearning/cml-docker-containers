# list of subdirectories containing a Dockerfile (skip dirs with .disabled)
SUBDIRS := $(shell find containers -type f -name Dockerfile -exec dirname {} \; | sort -u | while read -r d; do if [ ! -f "$$d/.disabled" ]; then echo "$$d"; fi; done)

# define the package name
include templates/pkg.mk
LVIMAGES := BUILD/debian/$(PKG)/var/lib/libvirt/images

# timestamp for ISO naming; can be overridden via make iso TS=...
TS ?= $(shell date -u +%Y%m%d)
 
SHELL_FILES := $(shell find scripts tests -type f -name '*.sh' -print 2>/dev/null)

.PHONY: build test format format-check lint $(SUBDIRS)
build: $(SUBDIRS)

.PHONY: format
format:
	@shfmt -w -i 2 -ci $(SHELL_FILES)

.PHONY: format-check
format-check:
	@shfmt -d -i 2 -ci $(SHELL_FILES)

.PHONY: lint
lint:
	@shellcheck -x -P . $(SHELL_FILES)

.PHONY: test
test:
	@TEST_VERBOSE="$(if $(TEST_VERBOSE),$(TEST_VERBOSE),1)" tests/latest-functions-test.sh
	@TEST_VERBOSE="$(if $(TEST_VERBOSE),$(TEST_VERBOSE),1)" tests/get-version-test.sh
	@TEST_VERBOSE="$(if $(TEST_VERBOSE),$(TEST_VERBOSE),1)" tests/latest-test.sh
 
$(SUBDIRS):
	$(MAKE) -C $@
 
.PHONY: clean
clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done
	@rm -rf BUILD/debian/$(PKG)
	@cd BUILD && ( command -v dh_clean >/dev/null 2>&1 && dh_clean || true )

.PHONY: iso iso-list clean-iso
# Split ISO build: uses per-subdir file 'iso-name' containing a suffix like "", "-extras", "-big"
# Builds one ISO per suffix group with constant volume label REFPLAT.
iso: build
	@scripts/build-split-isos.sh "$(TS)" "$(SUBDIRS)" "$(LVIMAGES)"

# Show mapping of modules to suffixes and predicted ISO names
iso-list:
	@set -e; \
	suffixes=$$(for d in $(SUBDIRS); do [ -f "$$d/iso-name" ] && cat "$$d/iso-name" || echo "services"; done | tr -d '\r' | sed -E 's/[[:space:]]+$$//' | sort -u); \
	echo "Discovered suffix groups:"; \
	for sfx in $$suffixes; do echo "  group: '"$$sfx"' -> refplat-$(TS)-"$$sfx".iso"; done; \
	echo "Module assignments:"; \
	for d in $(SUBDIRS); do \
		[ -f "$$d/iso-name" ] && sfx=$$(cat "$$d/iso-name" | tr -d '\n' | sed -E 's/[[:space:]]+$$//') || sfx="services"; \
		echo "  $$d -> '"$$sfx"'"; \
	done

# Clean ISO outputs and staging trees
clean-iso:
	@rm -f refplat-$(TS)-*.iso; \
	rm -rf $(LVIMAGES)/iso-staging-*;

 
.PHONY: deb
deb: build
	cd BUILD && dpkg-buildpackage --build=binary --no-sign --no-check-builddeps
 
.PHONY: definitions
definitions:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir definitions; \
	done

