include ../../templates/debian-trixie.mk

VERSION      := $(shell bash ../../scripts/get_version.sh deb $(DEBIAN_TRIXIE_INDEXES) "net-tools")
NAME         := net-tools
DESC         := Networking tools node
FULLDESC     := $(DESC) $(VERSION)
