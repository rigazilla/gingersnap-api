# Setting SHELL to bash allows bash commands to be executed by recipes.
# This is a requirement for 'setup-envtest.sh' in the test target.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

.PHONY: all
all: lint

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

.PHONY: lint
lint:  lint-cache ## Run protoc-gen-lint against the whole API

.PHONY: lint-cache
lint-cache: protoc protoc-gen-lint ## Run protoc-gen-lint against protobuf API
	PATH=$(LOCALBIN):$(PATH) $(PROTOC) 	--lint_out=. --lint_out=sort_imports:. \
	          	--lint_opt=Mconfig/cache/v1alpha1/cache.proto=github.com/gingersnap-project/operator/api/v1alpha1,Mconfig/cache/v1alpha1/rules.proto=github.com/gingersnap-project/operator/api/v1alpha1 \
			  	config/cache/v1alpha1/*.proto

##@ Build Dependencies

## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

## Tool Binaries
PROTOC ?= $(LOCALBIN)/protoc
PROTOC_GEN_LINT ?= $(LOCALBIN)/protoc-gen-lint
## Tool Versions
PROTOC_VERSION ?= 21.9
PROTOC_GEN_LINT_VERSION ?= v0.3.0

.PHONY: protoc-gen-lint
export PROTOC_GEN_LINT = ./bin/protoc-gen-lint
protoc-gen-lint: $(LOCALBIN) ## Download protc-gen-lint locally if necessary.
ifeq (,$(wildcard $(PROTOC_GEN_LINT)))
	@{ \
	set -e ;\
	mkdir -p $(dir $(PROTOC_GEN_LINT)) ;\
	curl -sSLo protoc-gen-lint.zip https://github.com/ckaznocha/protoc-gen-lint/releases/download/$(PROTOC_GEN_LINT_VERSION)/protoc-gen-lint_linux_amd64.zip ;\
	unzip -DD -d $(LOCALBIN) protoc-gen-lint.zip protoc-gen-lint ;\
	chmod u+x $(PROTOC_GEN_LINT) ;\
	}
endif

.PHONY: protoc
export PROTOC = ./bin/protoc
protoc: $(LOCALBIN) ## Download protoc locally if necessary.
ifeq (,$(wildcard $(PROTOC)))
ifeq (,$(shell (protoc 2>/dev/null  && protoc --version) | grep 'libprotoc $(PROTOC_VERSION)' ))
	@{ \
	set -e ;\
	mkdir -p $(dir $(PROTOC)) ;\
	curl -sSLo protoc.zip https://github.com/protocolbuffers/protobuf/releases/download/v$(PROTOC_VERSION)/protoc-$(PROTOC_VERSION)-linux-x86_64.zip ;\
	unzip -DD protoc.zip bin/protoc ;\
	}
endif
endif
