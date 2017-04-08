.PHONY:cross-compile relese clean create-release upload-assets _token-specified?

SHELL:=/bin/bash

OS:=linux darwin windows freebsd
ARCH:=amd64
BUILD:=./build

cross-compile:
	@for os in $(OS); do \
		for arch in $(ARCH); do \
			cmd="env GOOS=$$os GOARCH=$$arch go build -o $(BUILD)/$$os-$$arch/devops" ;\
			echo $$cmd ;\
			$$cmd ;\
		done ;\
	done

tar-and-name:
	@set -e ;\
	for os in $(OS); do \
		for arch in $(ARCH); do \
			cmd="cd $(BUILD)/$$os-$$arch && tar -czf devops-$(VERSION)-$$os-$$arch.tar.gz devops && cd -" ;\
			echo $$cmd ;\
			sh -c "$$cmd" ;\
		done ;\
	done


RELEASE-URL:=https://api.github.com/repos/lloydkirk/devops/releases
UPLOAD-URL:=https://uploads.github.com/repos/lloydkirk/devops/releases
CURL-ARGS:=-H'Accept: application/vnd.github.v3+json'
ASSET-HEADER:=-H'Content-Type: application/gzip'
POST:=curl -sXPOST $(CURL-ARGS)
GET:=curl -sXGET $(CURL-ARGS)
SIMPLE-AUTH:=$(GH_USER):$(GH_TOKEN)
VERSION:=$(shell cat VERSION)

_token-specified?:
ifeq ($(GH_TOKEN),)
	$(error GH_TOKEN not specified)
endif

_user-specified?:
ifeq ($(GH_USER),)
	$(error GH_USER not specified)
endif

create-release:
	@set -e ;\
	post_data=$$(tr -d ' ' <<< '{ \
		\"tag_name\": "$(VERSION)" \
	}') ;\
	cmd="$(POST) $(RELEASE-URL) -d$$post_data" ;\
	echo $$cmd ;\
	$$cmd -u'$(GH_USER):$(GH_TOKEN)'

upload-assets:
	@set -e ;\
	release_id=$$($(GET) $(RELEASE-URL)/latest | jq '.id') ;\
	for os in $(OS); do \
		for arch in $(ARCH); do \
			cmd="$(POST) $(ASSET-HEADER) --data-binary @devops-$(VERSION)-$$os-$$arch.tar.gz $(UPLOAD-URL)/$$release_id/assets?name=devops-$(VERSION)-$$os-$$arch.tar.gz" ;\
			echo $$cmd ;\
			sh -c "cd $(BUILD)/$$os-$$arch && $$cmd -u'$(GH_USER):$(GH_TOKEN)' && cd -" ;\
		done ;\
	done

travis-build-release: _user-specified? _token-specified? cross-compile tar-and-name create-release upload-assets

clean:
	rm -rf $(BUILD)
