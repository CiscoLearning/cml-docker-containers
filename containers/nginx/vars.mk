VERSION      := $(shell bash ../../scripts/latest.sh "nginx")
NAME         := nginx
DESC         := Nginx web server
FULLDESC     := $(DESC) $(VERSION)
