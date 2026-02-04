VERSION      := $(shell bash ../../scripts/get_version.sh apk "https://dl-cdn.alpinelinux.org/alpine/latest-stable/community/x86_64/APKINDEX.tar.gz" "frr")
NAME         := frr
DESC         := Free Range Routing
FULLDESC     := $(DESC) (frr) $(VERSION)

