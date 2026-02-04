VERSION      := $(shell bash ../../scripts/get_version.sh deb "https://packages.mozilla.org/apt/dists/mozilla/main/binary-amd64/Packages" "firefox")
NAME         := firefox
DESC         := Firefox
FULLDESC     := $(DESC) $(VERSION)
