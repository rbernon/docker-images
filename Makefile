STEAMRT_VERSION = $(shell cat $(HOME)/.steam/root/ubuntu12_32/steam-runtime/version.txt | tr '_' ' ' | awk '{print $$2}')
STEAMRT_URLBASE = http://repo.steampowered.com/steamrt-images-scout/snapshots/$(STEAMRT_VERSION)
STEAMRT_SDKBASE = com.valvesoftware.SteamRuntime.Sdk

all steamrt: docker-steamrt-amd64 docker-steamrt-i386
all proton: docker-proton-amd64 docker-proton-i386

$(STEAMRT_VERSION)/$(STEAMRT_SDKBASE)-%: $(shell mkdir -p $(STEAMRT_VERSION))
	wget $(STEAMRT_URLBASE)/$(STEAMRT_SDKBASE)-$* -O $@
$(STEAMRT_VERSION)/steam-runtime.tar.xz: $(shell mkdir -p $(STEAMRT_VERSION))
	wget $(STEAMRT_URLBASE)/steam-runtime.tar.xz -O $@

.PHONY: version
version:
	@echo $(STEAMRT_VERSION)

.PHONY: push
push:
	docker push rbernon/steamrt-amd64:$(STEAMRT_VERSION)
	docker push rbernon/steamrt-amd64:latest
	docker push rbernon/steamrt-i386:$(STEAMRT_VERSION)
	docker push rbernon/steamrt-i386:latest
	docker push rbernon/proton-amd64:$(STEAMRT_VERSION)
	docker push rbernon/proton-amd64:latest
	docker push rbernon/proton-i386:$(STEAMRT_VERSION)
	docker push rbernon/proton-i386:latest

.PHONY: docker-steamrt-amd64
docker-steamrt-amd64: $(STEAMRT_VERSION)/$(STEAMRT_SDKBASE)-amd64,i386-scout-sysroot.Dockerfile $(STEAMRT_VERSION)/$(STEAMRT_SDKBASE)-amd64,i386-scout-sysroot.tar.gz
	docker build -f $< \
	  -t rbernon/steamrt-amd64:$(STEAMRT_VERSION) \
	  -t rbernon/steamrt-amd64:latest \
	  $(STEAMRT_VERSION)

.PHONY: docker-steamrt-i386
docker-steamrt-i386: $(STEAMRT_VERSION)/$(STEAMRT_SDKBASE)-i386-scout-sysroot.Dockerfile $(STEAMRT_VERSION)/$(STEAMRT_SDKBASE)-i386-scout-sysroot.tar.gz
	docker build -f $< \
	  -t rbernon/steamrt-i386:$(STEAMRT_VERSION) \
	  -t rbernon/steamrt-i386:latest \
	  $(STEAMRT_VERSION)

BASE_IMAGE_i686 = i386/ubuntu:12.04
BASE_IMAGE_x86_64 = ubuntu:12.04

LIBISL_VERSION = 0.22.1
BINUTILS_VERSION = 2.35
GCC_VERSION = 9.3.0
MINGW_VERSION = 7.0.0

define create-libisl-rules
.PHONY: libisl-$(1)
all libisl: libisl-$(1)
libisl-$(1): libisl.Dockerfile
	rm -rf build; mkdir -p build
	docker build -f $$< \
	  --build-arg ARCH=$(1) \
	  --build-arg TARGET=$(2) \
	  --build-arg BASE_IMAGE=$(BASE_IMAGE_$(1)) \
	  --build-arg LIBISL_VERSION=$(LIBISL_VERSION) \
	  -t rbernon/libisl-$(1):$(LIBISL_VERSION) \
	  -t rbernon/libisl-$(1):latest \
	  build
push::
	docker push rbernon/libisl-$(1):$(LIBISL_VERSION)
	docker push rbernon/libisl-$(1):latest
endef

$(eval $(call create-libisl-rules,i686))
$(eval $(call create-libisl-rules,x86_64))

define create-binutils-rules
.PHONY: binutils-$(1)-$(2)
all binutils: binutils-$(1)-$(2)
binutils-$(1)-$(2): binutils.Dockerfile | libisl-$(1)
	rm -rf build; mkdir -p build
	docker build -f $$< \
	  --build-arg ARCH=$(1) \
	  --build-arg TARGET=$(2) \
	  --build-arg BASE_IMAGE=$(BASE_IMAGE_$(1)) \
	  --build-arg LIBISL_VERSION=$(LIBISL_VERSION) \
	  --build-arg BINUTILS_VERSION=$(BINUTILS_VERSION) \
	  -t rbernon/binutils-$(1)-$(2):$(BINUTILS_VERSION) \
	  -t rbernon/binutils-$(1)-$(2):latest \
	  build
push::
	docker push rbernon/binutils-$(1)-$(2):$(BINUTILS_VERSION)
	docker push rbernon/binutils-$(1)-$(2):latest
endef

$(eval $(call create-binutils-rules,i686,w64-mingw32))
$(eval $(call create-binutils-rules,i686,linux-gnu))
$(eval $(call create-binutils-rules,x86_64,w64-mingw32))
$(eval $(call create-binutils-rules,x86_64,linux-gnu))

define create-mingw-rules
.PHONY: mingw-$(1)
all mingw: mingw-$(1) | binutils-$(1)-w64-mingw32 libisl-$(1)
mingw-$(1): mingw.Dockerfile
	rm -rf build; mkdir -p build
	docker build -f $$< \
	  --build-arg ARCH=$(1) \
	  --build-arg BASE_IMAGE=$(BASE_IMAGE_$(1)) \
	  --build-arg LIBISL_VERSION=$(LIBISL_VERSION) \
	  --build-arg BINUTILS_VERSION=$(BINUTILS_VERSION) \
	  --build-arg MINGW_VERSION=$(MINGW_VERSION) \
	  --build-arg GCC_VERSION=$(GCC_VERSION) \
	  -t rbernon/mingw-$(1):$(MINGW_VERSION) \
	  -t rbernon/mingw-$(1):latest \
	  build
push::
	docker push rbernon/mingw-$(1):$(MINGW_VERSION)
	docker push rbernon/mingw-$(1):latest
endef

$(eval $(call create-mingw-rules,i686))
$(eval $(call create-mingw-rules,x86_64))

define create-gcc-rules
.PHONY: gcc-$(1)-$(2)
all gcc: gcc-$(1)-$(2)
gcc-$(1)-$(2): gcc.Dockerfile | mingw-$(1) binutils-$(1)-$(2)
	rm -rf build; mkdir -p build
	docker build -f $$< \
	  --build-arg ARCH=$(1) \
	  --build-arg TARGET=$(2) \
	  --build-arg BASE_IMAGE=$(BASE_IMAGE_$(1)) \
	  --build-arg LIBISL_VERSION=$(LIBISL_VERSION) \
	  --build-arg BINUTILS_VERSION=$(BINUTILS_VERSION) \
	  --build-arg MINGW_VERSION=$(MINGW_VERSION) \
	  --build-arg GCC_VERSION=$(GCC_VERSION) \
	  -t rbernon/gcc-$(1)-$(2):$(GCC_VERSION) \
	  -t rbernon/gcc-$(1)-$(2):latest \
	  build
push::
	docker push rbernon/gcc-$(1)-$(2):$(GCC_VERSION)
	docker push rbernon/gcc-$(1)-$(2):latest
endef

$(eval $(call create-gcc-rules,i686,linux-gnu))
$(eval $(call create-gcc-rules,x86_64,linux-gnu))
$(eval $(call create-gcc-rules,i686,w64-mingw32))
$(eval $(call create-gcc-rules,x86_64,w64-mingw32))

.PHONY: docker-proton-amd64
docker-proton-amd64: proton.Dockerfile docker-steamrt-amd64
	rm -rf build; mkdir -p build
	docker build -f $< \
	  --build-arg ARCH=x86_64 \
	  --build-arg BASE_IMAGE=rbernon/steamrt-amd64:$(STEAMRT_VERSION) \
	  --build-arg BINUTILS_VERSION=2.35 \
	  --build-arg BISON_VERSION=3.5 \
	  --build-arg CCACHE_VERSION=3.7.9 \
	  --build-arg GCC_VERSION=9.3.0 \
	  --build-arg ISL_VERSION=0.22 \
	  --build-arg MINGW_VERSION=v7.0.0 \
	  --build-arg RUST_VERSION=1.44.1 \
	  -t rbernon/proton-amd64:$(STEAMRT_VERSION) \
	  -t rbernon/proton-amd64:latest \
	  build

.PHONY: docker-proton-i386
docker-proton-i386: proton.Dockerfile docker-steamrt-i386
	rm -rf build; mkdir -p build
	docker build -f $< \
	  --build-arg ARCH=i686 \
	  --build-arg BASE_IMAGE=rbernon/steamrt-i386:$(STEAMRT_VERSION) \
	  --build-arg BINUTILS_VERSION=2.35 \
	  --build-arg BISON_VERSION=3.5 \
	  --build-arg CCACHE_VERSION=3.7.9 \
	  --build-arg GCC_VERSION=9.3.0 \
	  --build-arg ISL_VERSION=0.22 \
	  --build-arg MINGW_VERSION=v7.0.0 \
	  --build-arg RUST_VERSION=1.44.1 \
	  -t rbernon/proton-i386:$(STEAMRT_VERSION) \
	  -t rbernon/proton-i386:latest \
	  build
