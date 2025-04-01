# list of subdirectories containing a Dockerfile
SUBDIRS := $(shell find . -type f -name Dockerfile -exec dirname {} \;)

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for dir in $(SUBDIRS); do \
			$(MAKE) -C $$dir clean; \
	done
	cd BUILD/refplat-images-docker_all/var/lib/libvirt/images/node-definitions && find . -type f -not -name ".gitkeep" -delete 
	cd BUILD/refplat-images-docker_all/var/lib/libvirt/images/virl-base-images && find . -type d -exec rm -rf {} \;
	-rm BUILD/*.deb

.PHONY: all clean $(SUBDIRS)

deb:
	cd BUILD; dpkg-deb --build -Znone refplat-images-docker_all
