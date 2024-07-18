.PHONY: build push

BUILDVERSION ?= latest
DOCKERUSER ?= goeshere


build:
	docker buildx build --load --platform linux/amd64 . -t $(DOCKERUSER)/mastodon:$(BUILDVERSION)

push:
	docker push  $(DOCKERUSER)/mastodon:$(BUILDVERSION)


build-alpha:
	docker buildx build --load --platform linux/amd64 . -t $(DOCKERUSER)/mastodon-alpha:$(BUILDVERSION)

push-alpha:
	docker push  $(DOCKERUSER)/mastodon-alpha:$(BUILDVERSION)


build-beta:
	docker buildx build --load --platform linux/amd64 . -t $(DOCKERUSER)/mastodon-beta:$(BUILDVERSION)

push-beta:
	docker push  $(DOCKERUSER)/mastodon-beta:$(BUILDVERSION)

