include ../../templates/debian-trixie.mk

VERSION      := $(shell bash ../../scripts/get_version.sh deb $(DEBIAN_TRIXIE_INDEXES) "freeradius")
NAME         := radius
DESC         := FreeRADIUS server
FULLDESC     := $(DESC) $(VERSION)
