VERSION      := $(shell bash ../../scripts/get_version.sh deb "https://deb.debian.org/debian/dists/trixie/main/binary-amd64/Packages.gz" "net-tools")
NAME         := net-tools
DESC         := Networking tools node
FULLDESC     := $(DESC) $(VERSION)
