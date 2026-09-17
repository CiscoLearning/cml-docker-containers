include ../../templates/debian-trixie.mk

VERSION      := $(shell bash ../../scripts/get_version.sh deb $(DEBIAN_TRIXIE_INDEXES) "chromium")
NAME         := chromium
DESC         := Chromium
FULLDESC     := $(DESC) $(VERSION)
