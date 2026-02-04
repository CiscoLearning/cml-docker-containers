VERSION      := $(shell bash ../../scripts/get_version.sh deb "https://dl.google.com/linux/chrome/deb/dists/stable/main/binary-amd64/Packages" "google-chrome-stable")
NAME         := chrome
DESC         := Google Chrome stable
FULLDESC     := $(DESC) $(VERSION)
