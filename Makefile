# Makefile for building and running docker container
# Adapted from https://hexdocs.pm/distillery/guides/working_with_docker.html
#
.PHONY: help

APP_NAME ?= impact_oscillator#`grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g'`
APP_VSN ?= `grep 'version:' mix.exs | cut -d '"' -f2`
BUILD ?= `git rev-parse --short HEAD`

help: ##
	@echo "$(APP_NAME):$(APP_VSN)-$(BUILD)"
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image
	docker build --no-cache \
	    -t $(APP_NAME):$(APP_VSN)-$(BUILD) \
	    -t $(APP_NAME):latest .

run: ## Run the app in Docker
	docker run --expose 4000 -p 4000:4000 --rm -it $(APP_NAME):latest

test: #build
	docker run --entrypoint mix $(APP_NAME):latest test
