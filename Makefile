.PHONY:cross-compile relese clean

OS:=linux darwin windows freebsd
ARCH:=amd64
BUILD:=./build
RELEASE-URL:=https://api.github.com/repos/lloydkirk/devops/releases

cross-compile:
	@for os in $(OS); do \
		for arch in $(ARCH); do \
			cmd="env GOOS=$$os GOARCH=$$arch go build -o $(BUILD)/$$os-$$arch/devops" ;\
			echo $$cmd ;\
			$$cmd ;\
		done ;\
	done

create-release:
	@set -e ;\
	version=$$(devops version print) \
	post_data=$$(tr -d ' ' <<< "{ \
		\"tag_name\": \"$$version\" \
	}") \
	cmd="curl -sXGET $(RELEASE-URL) -d$$post_data";\
	echo $$cmd ;\
	$$cmd

release:
	@for os in $(OS); do \
		for arch in $(ARCH); do \
			post_data=$$(tr -d ' ' <<< '{ \
				"tag_name": "$(VERSION)" \
			}') ;\
			cmd="curl -sXGET $(RELEASE-URL) -d$$post_data";\
			echo $$cmd ;\
		done ;\
	done

clean:
	rm -rf $(BUILD)
