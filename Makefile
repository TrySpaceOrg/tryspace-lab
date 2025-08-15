# Makefile for TrySpace Lab development
.PHONY: build clean clean-cli clean-fsw clean-gsw clean-sim cfg cli container debug env fsw gsw help sim start stop uninstall

# Build image name
export BUILD_IMAGE ?= tryspaceorg/tryspace-lab

# Common paths
CFG_DIR := $(CURDIR)/cfg
ENV_FILE := $(CFG_DIR)/.env

# Commands
build: env
	$(MAKE) sim
	$(MAKE) fsw
	$(MAKE) gsw

cfg: container
	docker run --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR)/cfg --user $(shell id -u):$(shell id -g) $(BUILD_IMAGE) python3 tryspace-orchestrator.py

clean:
	$(MAKE) stop
	@if docker image inspect $(BUILD_IMAGE):latest >/dev/null 2>&1; then \
		$(MAKE) clean-cli; \
		$(MAKE) clean-fsw; \
		$(MAKE) clean-gsw; \
		$(MAKE) clean-sim; \
		docker volume ls -q --filter "name=gsw-data" | xargs -r docker volume rm
		docker volume ls -q --filter "name=simulith_ipc" | xargs -r docker volume rm
	else \
		echo "Docker image $(BUILD_IMAGE) does not exist. Skipping clean subcommands."; \
	fi
	rm -f $(ENV_FILE) $(CFG_DIR)/active.yaml $(CFG_DIR)/build.yaml 

clean-cli:
	@for dir in $(CURDIR)/comp/*/cli ; do \
		if [ -f "$$dir/Makefile" ]; then \
			$(MAKE) -C "$$dir" clean; \
		fi; \
	done

clean-fsw:
	cd fsw && $(MAKE) clean

clean-gsw:
	cd gsw && $(MAKE) clean

clean-sim:
	@for dir in $(CURDIR)/comp/* ; do \
		if [ -d "$$dir" ] && [ -f "$$dir/Makefile" ]; then \
			$(MAKE) -C "$$dir" clean; \
		fi; \
	done
	cd simulith && $(MAKE) clean

cli: env
	$(MAKE) container
	@for dir in $(CURDIR)/comp/*/cli ; do \
        if [ -f "$$dir/Makefile" ]; then \
            $(MAKE) -C "$$dir" runtime; \
        fi; \
    done
	cd $(CURDIR)/simulith && $(MAKE) director && $(MAKE) server
	docker compose -f ./cfg/cli-compose.yml up

container: cfg/Dockerfile.base
	docker build -t $(BUILD_IMAGE) -f cfg/Dockerfile.base --build-arg USER_ID=$(shell id -u) --build-arg GROUP_ID=$(shell id -g) .

debug: env
	docker run --rm -it -v $(CURDIR):$(CURDIR) --name "tryspace_fsw_debug" -w $(CURDIR) --user $(shell id -u):$(shell id -g) --sysctl fs.mqueue.msg_max=10000 --ulimit rtprio=99 --cap-add=sys_nice $(BUILD_IMAGE) /bin/bash

env:
	@command -v docker >/dev/null 2>&1 || { echo "Error: docker is not installed or not in PATH."; exit 1; }
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "Creating $(ENV_FILE) with current user UID/GID..."; \
		mkdir -p $(CFG_DIR); \
		echo "UID=$$(id -u)" > $(ENV_FILE); \
		echo "GID=$$(id -g)" >> $(ENV_FILE); \
		echo "Created $(ENV_FILE)"; \
	fi
	$(MAKE) cfg

fsw: env
	cd $(CURDIR)/fsw && $(MAKE) runtime

gsw: env
	cd $(CURDIR)/gsw && $(MAKE) runtime

help:
	@echo "Usage: make <target>"
	@echo "Targets:"
	@echo "  build         - Build the full runtime environment"
	@echo "  cfg           - Run orchestrator to configure environment"
	@echo "  cli           - Build CLI and start CLI services"
	@echo "  clean         - Remove build artifacts and stop services"
	@echo "  clean-cli     - Clean CLI components"
	@echo "  clean-fsw     - Clean FSW components"
	@echo "  clean-gsw     - Clean GSW components"
	@echo "  clean-sim     - Clean simulation components"
	@echo "  container     - Build the Docker container"
	@echo "  debug         - Start a debug shell in the container"
	@echo "  env           - Create .env file and check required tools"
	@echo "  fsw           - Build FSW"
	@echo "  gsw           - Build GSW"
	@echo "  sim           - Build Simulith and component simulators"
	@echo "  start         - Start lab services"
	@echo "  stop          - Stop lab and CLI services, clean up Docker images"
	@echo "  uninstall     - Remove containers, images, volumes, and networks"

sim: env
	@for dir in $(CURDIR)/comp/*/sim ; do \
		if [ -d "$$dir" ] && [ -f "$$dir/Makefile" ]; then \
			echo "Building component in $$dir"; \
			$(MAKE) -C "$$dir" runtime; \
		fi; \
	done
	cd $(CURDIR)/simulith && $(MAKE) director && $(MAKE) server

start: env
	docker compose -f ./cfg/lab-compose.yml up

stop:
	docker compose -f ./cfg/cli-compose.yml down
	docker compose -f ./cfg/lab-compose.yml down
	docker images -f "dangling=true" -q | xargs -r docker rmi

uninstall: clean
	docker ps -a --filter "name=tryspace-" -q | xargs -r docker rm -f
	docker images "tryspace-*" -q | xargs -r docker rmi
	docker volume ls -q --filter "name=gsw-data" | xargs -r docker volume rm
	docker volume ls -q --filter "name=simulith_ipc" | xargs -r docker volume rm
	docker network ls -q --filter "name=tryspace-net" | xargs -r docker network rm
	docker network ls -q --filter "name=cfg_tryspace-net" | xargs -r docker network rm
	@echo ""
	@echo "To cleanup everything docker even unrelated to TrySpace: "
	@echo "  docker system prune -a"
	@echo ""
