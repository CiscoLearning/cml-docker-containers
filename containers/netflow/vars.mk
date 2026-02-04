VERSION      := $(shell bash ../../scripts/get_version.sh deb "https://archive.debian.org/debian/dists/buster/main/binary-amd64/Packages.gz" "flow-tools")
NAME         := netflow
DESC         := Netflow daemon
FULLDESC     := $(DESC) $(VERSION)
