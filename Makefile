#ifneq (,$(wildcard ./.env))
#    include .env
#endif
#.EXPORT_ALL_VARIABLES:

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

#.PHONY: users
#users: ## Create the required user and group.
#	sudo scripts/users.sh "$(PUID)" "$(PGID)" "$(APP_USER)" "$(APP_GROUP)"
#
#.PHONY: masq
#masq: ## Enable network masquerading.
#	sudo scripts/masq.sh
#
#.PHONY: podman
#podman: ## Install Podman.
#	sudo scripts/podman.sh


