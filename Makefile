.PHONY:cross-compile relese clean create-release upload-assets _token-specified?

SHELL:=/bin/bash

bootstrap:
	curl -H'Accept: application/octet-stream' -sXGET https://api.github.com/repos/lloydkirk/devops/releases/assets/3611154 -L | tar -xzO > devops
	chmod +x devops

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
	version=$$(./devops version print) ;\
	for os in $(OS); do \
		for arch in $(ARCH); do \
			cmd="cd $(BUILD)/$$os-$$arch && tar -czf devops-$$version-$$os-$$arch.tar.gz devops && cd -" ;\
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
	version=$$(./devops version print) ;\
	post_data=$$(tr -d ' ' <<< "{ \
		\"tag_name\": \"$$version\" \
	}") ;\
	cmd="$(POST) $(RELEASE-URL) -d$$post_data" ;\
	echo $$cmd ;\
	$$cmd -u'$(GH_USER):$(GH_TOKEN)'

upload-assets:
	@set -e ;\
	version=$$(./devops version print) ;\
	release_id=$$($(GET) $(RELEASE-URL)/latest | jq '.id') ;\
	for os in $(OS); do \
		for arch in $(ARCH); do \
			cmd="$(POST) $(ASSET-HEADER) --data-binary @devops-$$version-$$os-$$arch.tar.gz $(UPLOAD-URL)/$$release_id/assets?name=devops-$$version-$$os-$$arch.tar.gz" ;\
			echo $$cmd ;\
			sh -c "cd $(BUILD)/$$os-$$arch && $$cmd -u'$(GH_USER):$(GH_TOKEN)' && cd -" ;\
		done ;\
	done

travis-build-release: _user-specified? _token-specified? bootstrap cross-compile tar-and-name create-release upload-assets

clean:
	rm -rf $(BUILD)
