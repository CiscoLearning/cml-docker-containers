include vars.mk
include ../templates/build.mk

IMG := te-ea.tgz

# Override image preparation via PREPARE_IMAGE_CMD for template
PREPARE_IMAGE_CMD = \
	docker pull thousandeyes/enterprise-agent:latest-agent; \
	docker tag thousandeyes/enterprise-agent:latest-agent $(NAME):$(TAG)
