.PHONY: build push

BUILDVERSION ?= latest
DOCKERUSER ?= goeshere


build:
	docker buildx build --load --platform linux/amd64 . -t $(DOCKERUSER)/mastodon:$(BUILDVERSION)

push:
	docker push  $(DOCKERUSER)/mastodon:$(BUILDVERSION)
