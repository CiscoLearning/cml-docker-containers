include ../../templates/debian-trixie.mk

VERSION      := $(shell bash ../../scripts/get_version.sh deb $(DEBIAN_TRIXIE_INDEXES) "syslog-ng")
NAME         := syslog
DESC         := Syslog NG server
FULLDESC     := $(DESC) $(VERSION)
