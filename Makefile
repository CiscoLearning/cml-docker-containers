# list of subdirectories containing a Dockerfile
SUBDIRS := $(shell find . -type f -name Dockerfile -exec dirname {} \;)

all: $(SUBDIRS) deb

$(SUBDIRS):
	$(MAKE) -C $@

# build:
# 	for dir in $(SUBDIRS); do \
# 			$(MAKE) -C $$dir build; \
# 	done

clean:
	# for dir in $(SUBDIRS); do \
	# 		$(MAKE) -C $$dir clean; \
	# done
	cd BUILD/refplat-images-docker_all/var/lib/libvirt/images/node-definitions && find . -depth -type f -not -name ".gitkeep" -delete 
	cd BUILD/refplat-images-docker_all/var/lib/libvirt/images/virl-base-images && find . -depth -type d -exec rm -rf {} \;
	-rm BUILD/*.deb

.PHONY: all clean $(SUBDIRS)

deb:
	cd BUILD; dpkg-deb --build -Znone refplat-images-docker_all
