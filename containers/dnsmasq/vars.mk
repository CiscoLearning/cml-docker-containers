include ../../templates/debian-trixie.mk

VERSION      := $(shell bash ../../scripts/get_version.sh deb $(DEBIAN_TRIXIE_INDEXES) "dnsmasq")
NAME         := dnsmasq
DESC         := Dnsmasq server
FULLDESC     := $(DESC) (DHCP, DNS, TFTP) $(VERSION)
