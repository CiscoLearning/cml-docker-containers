VERSION      := $(shell bash ../../scripts/latest.sh "thousandeyes/enterprise-agent" "latest-agent")
NAME         := thousandeyes-ea
DESC         := ThousandEyes Enterprise Agent
FULLDESC     := $(DESC) $(VERSION)
