VERSION      := $(shell bash ../../scripts/get_version.sh deb "https://deb.debian.org/debian/dists/trixie/main/binary-amd64/Packages.gz" "dnsmasq")
NAME         := dnsmasq
DESC         := Dnsmasq server
FULLDESC     := $(DESC) (DHCP, DNS, TFTP) $(VERSION)
