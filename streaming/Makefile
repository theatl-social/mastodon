.PHONY: build push

BUILDVERSION ?= latest
DOCKERUSER ?= goeshere


build:
	docker buildx build -f ./Dockerfile --load --platform linux/amd64 ../ -t $(DOCKERUSER)/mastodon-streaming:$(BUILDVERSION)

push:
	docker push  $(DOCKERUSER)/mastodon-streaming:$(BUILDVERSION)
