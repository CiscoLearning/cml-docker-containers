VERSION      := $(shell bash ../../scripts/get_version.sh deb "https://deb.debian.org/debian/dists/trixie/main/binary-amd64/Packages.gz" "syslog-ng")
NAME         := syslog
DESC         := Syslog NG server
FULLDESC     := $(DESC) $(VERSION)
