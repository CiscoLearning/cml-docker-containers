VERSION      := $(shell bash ../../scripts/get_version.sh deb "https://deb.debian.org/debian/dists/trixie/main/binary-amd64/Packages.gz" "freeradius")
NAME         := radius
DESC         := FreeRadius server
FULLDESC     := $(DESC) $(VERSION)
