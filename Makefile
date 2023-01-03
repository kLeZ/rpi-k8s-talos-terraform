# Copyright (C) 2022 Alessandro Accardo
# 
# This file is part of klez-kluster-r08075.
# 
# klez-kluster-r08075 is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# klez-kluster-r08075 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with klez-kluster-r08075.  If not, see <http://www.gnu.org/licenses/>.

# Use some sensible default shell settings
SHELL := /bin/bash -o pipefail
.SILENT:
.DEFAULT_GOAL := help

# Default variables
MNT_DEVICE             ?= /dev/mmcblk0
OUTPUT_PATH = output

# Raspberry PI host and IP configuration
RPI_HOSTNAME     ?= rpi-kube-controlplane-01
RPI_IP           ?= 192.168.1.101
RPI_GATEWAY      ?= 192.168.1.1
RPI_DNS          ?= $(RPI_GATEWAY)

# Kubernetes configuration
KUBE_NODE_TYPE    ?= controlplane
KUBE_MASTER_VIP   ?= 192.168.1.100
KUBE_MASTER_IPS   ?= 192.168.1.101

# Raspbian image configuration
DISTRO_NAME             ?= talos
DISTRO_VERSION          ?= v1.2.5
DISTRO_IMAGE_VERSION    ?= metal-rpi_4-arm64
DISTRO_IMAGE_EXTENSION  ?= img.xz
DISTRO_URL				= https://github.com/siderolabs/$(DISTRO_NAME)/releases/download/$(DISTRO_VERSION)/$(DISTRO_IMAGE_VERSION).$(DISTRO_IMAGE_EXTENSION)

ifeq ($(DISTRO_IMAGE_EXTENSION),zip)
	decompress = unzip
	decompress_output = -d ./$(OUTPUT_PATH)/
endif
ifeq ($(DISTRO_IMAGE_EXTENSION),img.xz)
	decompress = xz -d
	decompress_output = 
endif

##@ Build
.PHONY: build
build: prepare format ## Build SD card with Kubernetes and automated cluster creation
	echo "Created a headless Kubernetes SD card with the following properties:"
	echo "Network:"
	echo "- Hostname: $(RPI_HOSTNAME)"
	echo "- Static IP: $(RPI_IP)"
	echo "- Gateway address: $(RPI_DNS)"
	echo "Kubernetes:"
	echo "- Node Type: $(KUBE_NODE_TYPE)"
	echo "- Control Plane Endpoint: $(KUBE_MASTER_VIP)"
	echo "- Control Plane IPs: $(KUBE_MASTER_IPS)"

##@ Download and SD Card management
.PHONY: format
format: $(OUTPUT_PATH)/$(DISTRO_IMAGE_VERSION).img ## Format the SD card with Talos
	echo "Formatting SD card with $(DISTRO_IMAGE_VERSION).img"
	sudo dd bs=4M if=./$(OUTPUT_PATH)/$(DISTRO_IMAGE_VERSION).img of=$(MNT_DEVICE) status=progress conv=fsync

$(OUTPUT_PATH)/$(DISTRO_IMAGE_VERSION).img: ## Download Talos image and extract to current directory
	rm -f ./$(OUTPUT_PATH)/$(DISTRO_IMAGE_VERSION).$(DISTRO_IMAGE_EXTENSION)
	echo "Downloading $(DISTRO_IMAGE_VERSION).img..."
	wget $(DISTRO_URL) -P ./$(OUTPUT_PATH)/
	$(decompress) ./$(OUTPUT_PATH)/$(DISTRO_IMAGE_VERSION).$(DISTRO_IMAGE_EXTENSION) $(decompress_output)
	rm -f ./$(OUTPUT_PATH)/$(DISTRO_IMAGE_VERSION).$(DISTRO_IMAGE_EXTENSION)

##@ Misc
.PHONY: help
help: ## Display this help
	awk \
	  'BEGIN { \
	    FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n" \
	  } /^[a-zA-Z_-]+:.*?##/ { \
	    printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 \
	  } /^##@/ { \
	    printf "\n\033[1m%s\033[0m\n", substr($$0, 5) \
	  }' $(MAKEFILE_LIST)

##@ Helpers
.PHONY: prepare
prepare: ## Create all necessary directories to be used in build
	mkdir -p ./$(OUTPUT_PATH)/
#	sudo sgdisk --zap-all $(MNT_DEVICE)
#	sudo dd if=/dev/zero of=$(MNT_DEVICE) bs=1M count=100 oflag=direct,dsync
