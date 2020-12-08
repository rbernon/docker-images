STEAMRT_VERSION = 0.20201124.0
STEAMRT_URLBASE = registry.gitlab.steamos.cloud

DOCKER_USER := rbernon

.PHONY: version
version:
	@echo $(STEAMRT_VERSION)

.PHONY: steamrt
all: steamrt
steamrt:
	-docker pull $(STEAMRT_URLBASE)/steamrt/soldier/sdk:$(STEAMRT_VERSION)
	docker tag $(STEAMRT_URLBASE)/steamrt/soldier/sdk:$(STEAMRT_VERSION) $(DOCKER_USER)/steamrt:$(STEAMRT_VERSION)
	docker tag $(STEAMRT_URLBASE)/steamrt/soldier/sdk:$(STEAMRT_VERSION) $(DOCKER_USER)/steamrt:latest
push-steamrt::
	-docker push $(DOCKER_USER)/steamrt:$(STEAMRT_VERSION)
	-docker push $(DOCKER_USER)/steamrt:latest

push:: push-steamrt

# this is just for building toolchain, as we do static builds it should
# not have any impact on the end result, but changing it will invalidate
# docker caches, so we need something that don't change much
BASE_IMAGE_i686 = i386/ubuntu:18.04
BASE_IMAGE_x86_64 = ubuntu:18.04

ISL_VERSION = 0.22.1
BINUTILS_VERSION = 2.35
GCC_VERSION = 9.3.0
MINGW_VERSION = 8.0.0
RUST_VERSION = 1.44.1

%.Dockerfile: %.Dockerfile.in
	sed -re 's!@DOCKER_USER@!$(DOCKER_USER)!g' \
	    -re 's!@BASE_IMAGE@!$(BASE_IMAGE)!g' \
	    -re 's!@ISL_VERSION@!$(ISL_VERSION)!g' \
	    -re 's!@BINUTILS_VERSION@!$(BINUTILS_VERSION)!g' \
	    -re 's!@GCC_VERSION@!$(GCC_VERSION)!g' \
	    -re 's!@MINGW_VERSION@!$(MINGW_VERSION)!g' \
	    -re 's!@RUST_VERSION@!$(RUST_VERSION)!g' \
	    $< >$@

%-i686.Dockerfile.in: %.Dockerfile.in
	sed -re 's!@ARCH@!i686!g' \
	    $< >$@

%-x86_64.Dockerfile.in: %.Dockerfile.in
	sed -re 's!@ARCH@!x86_64!g' \
	    $< >$@

%-linux-gnu.Dockerfile.in: %.Dockerfile.in
	sed -re 's!@TARGET@!linux-gnu!g' \
	    -re 's!@TARGET_FLAGS@!$(TARGET_FLAGS)!g' \
	    $< >$@

%-w64-mingw32.Dockerfile.in: %.Dockerfile.in
	sed -re 's!@TARGET@!w64-mingw32!g' \
	    -re 's!@TARGET_FLAGS@!$(TARGET_FLAGS)!g' \
	    $< >$@

define create-build-base-rules
.PHONY: build-base-$(1)
all build-base: build-base-$(1)
build-base-$(1): BASE_IMAGE = $(BASE_IMAGE_$(1))
build-base-$(1): build-base-$(1).Dockerfile
	rm -rf build; mkdir -p build
	-docker pull $(DOCKER_USER)/build-base-$(1):latest
	docker build -f $$< \
	  --cache-from=$(DOCKER_USER)/build-base-$(1):latest \
	  -t $(DOCKER_USER)/build-base-$(1):latest \
	  build
push-build-base-$(1)::
	docker push $(DOCKER_USER)/build-base-$(1):latest
push:: push-build-base-$(1)
endef

$(eval $(call create-build-base-rules,i686))
$(eval $(call create-build-base-rules,x86_64))

define create-binutils-rules
.PHONY: binutils-$(1)-$(2)
all binutils: binutils-$(1)-$(2)
binutils-$(1)-$(2): BASE_IMAGE = $(DOCKER_USER)/build-base-$(1):latest
binutils-$(1)-$(2): binutils-$(1)-$(2).Dockerfile
	rm -rf build; mkdir -p build
	-docker pull $(DOCKER_USER)/binutils-$(1)-$(2):$(BINUTILS_VERSION)
	docker build -f $$< \
	  --cache-from=$(DOCKER_USER)/binutils-$(1)-$(2):$(BINUTILS_VERSION) \
	  -t $(DOCKER_USER)/binutils-$(1)-$(2):$(BINUTILS_VERSION) \
	  -t $(DOCKER_USER)/binutils-$(1)-$(2):latest \
	  build
push-binutils-$(1)-$(2)::
	-docker push $(DOCKER_USER)/binutils-$(1)-$(2):$(BINUTILS_VERSION)
	-docker push $(DOCKER_USER)/binutils-$(1)-$(2):latest
push:: push-binutils-$(1)-$(2)
endef

$(eval $(call create-binutils-rules,i686,w64-mingw32))
$(eval $(call create-binutils-rules,i686,linux-gnu))
$(eval $(call create-binutils-rules,x86_64,w64-mingw32))
$(eval $(call create-binutils-rules,x86_64,linux-gnu))

define create-mingw-rules
.PHONY: mingw-$(2)-$(1)
all mingw: mingw-$(2)-$(1)
mingw-$(2)-$(1): BASE_IMAGE = $(DOCKER_USER)/build-base-$(1):latest
mingw-$(2)-$(1): mingw-$(2)-$(1).Dockerfile
	rm -rf build; mkdir -p build
	-docker pull $(DOCKER_USER)/mingw-$(2)-$(1):$(MINGW_VERSION)
	docker build -f $$< \
	  --cache-from=$(DOCKER_USER)/mingw-$(2)-$(1):$(MINGW_VERSION) \
	  -t $(DOCKER_USER)/mingw-$(2)-$(1):$(MINGW_VERSION) \
	  -t $(DOCKER_USER)/mingw-$(2)-$(1):latest \
	  build
push-mingw-$(2)-$(1)::
	-docker push $(DOCKER_USER)/mingw-$(2)-$(1):$(MINGW_VERSION)
	-docker push $(DOCKER_USER)/mingw-$(2)-$(1):latest
push:: push-mingw-$(2)-$(1)
endef

$(eval $(call create-mingw-rules,i686,headers))
$(eval $(call create-mingw-rules,i686,gcc))
$(eval $(call create-mingw-rules,i686,crt))
$(eval $(call create-mingw-rules,i686,pthreads))
$(eval $(call create-mingw-rules,i686,widl))
$(eval $(call create-mingw-rules,x86_64,headers))
$(eval $(call create-mingw-rules,x86_64,gcc))
$(eval $(call create-mingw-rules,x86_64,crt))
$(eval $(call create-mingw-rules,x86_64,pthreads))
$(eval $(call create-mingw-rules,x86_64,widl))

GCC_TARGET_FLAGS_w64-mingw32 = --disable-shared
GCC_TARGET_FLAGS_linux-gnu =

define create-gcc-rules
.PHONY: gcc-$(1)-$(2)
all gcc: gcc-$(1)-$(2)
gcc-$(1)-$(2): TARGET_FLAGS = $(GCC_TARGET_FLAGS_$(2))
gcc-$(1)-$(2): BASE_IMAGE = $(DOCKER_USER)/build-base-$(1):latest
gcc-$(1)-$(2): gcc-$(1)-$(2).Dockerfile
	rm -rf build; mkdir -p build
	-docker pull $(DOCKER_USER)/gcc-$(1)-$(2):$(GCC_VERSION)
	docker build -f $$< \
	  --cache-from=$(DOCKER_USER)/gcc-$(1)-$(2):$(GCC_VERSION) \
	  -t $(DOCKER_USER)/gcc-$(1)-$(2):$(GCC_VERSION) \
	  -t $(DOCKER_USER)/gcc-$(1)-$(2):latest \
	  build
push-gcc-$(1)-$(2)::
	-docker push $(DOCKER_USER)/gcc-$(1)-$(2):$(GCC_VERSION)
	-docker push $(DOCKER_USER)/gcc-$(1)-$(2):latest
push:: push-gcc-$(1)-$(2)
endef

$(eval $(call create-gcc-rules,i686,linux-gnu))
$(eval $(call create-gcc-rules,x86_64,linux-gnu))
$(eval $(call create-gcc-rules,i686,w64-mingw32))
$(eval $(call create-gcc-rules,x86_64,w64-mingw32))

PROTON_BASE_IMAGE = $(DOCKER_USER)/steamrt:$(STEAMRT_VERSION)

.PHONY: proton
all: proton
proton: BASE_IMAGE = $(PROTON_BASE_IMAGE)
proton: proton.Dockerfile
	rm -rf build; mkdir -p build
	-docker pull $(DOCKER_USER)/proton:$(STEAMRT_VERSION)
	docker build -f $< \
	  --cache-from=$(DOCKER_USER)/proton:$(STEAMRT_VERSION) \
	  -t $(DOCKER_USER)/proton:$(STEAMRT_VERSION) \
	  -t $(DOCKER_USER)/proton:latest \
	  build
push-proton::
	-docker push $(DOCKER_USER)/proton:$(STEAMRT_VERSION)
	-docker push $(DOCKER_USER)/proton:latest
push:: push-proton

WINE_BASE_IMAGE_i686 = i386/debian:unstable
WINE_BASE_IMAGE_x86_64 = debian:unstable

define create-wine-rules
.PHONY: wine-$(1)
all wine: wine-$(1)
wine-$(1): BASE_IMAGE = $(WINE_BASE_IMAGE_$(1))
wine-$(1): wine-$(1).Dockerfile
	rm -rf build; mkdir -p build
	-docker pull $(DOCKER_USER)/build-base-$(1):latest
	-docker pull $(DOCKER_USER)/binutils-$(1)-linux-gnu:$(BINUTILS_VERSION)
	-docker pull $(DOCKER_USER)/binutils-$(1)-w64-mingw32:$(BINUTILS_VERSION)
	-docker pull $(DOCKER_USER)/mingw-headers-$(1):$(MINGW_VERSION)
	-docker pull $(DOCKER_USER)/mingw-gcc-$(1):$(MINGW_VERSION)
	-docker pull $(DOCKER_USER)/mingw-crt-$(1):$(MINGW_VERSION)
	-docker pull $(DOCKER_USER)/mingw-pthreads-$(1):$(MINGW_VERSION)
	-docker pull $(DOCKER_USER)/mingw-widl-$(1):$(MINGW_VERSION)
	-docker pull $(DOCKER_USER)/gcc-$(1)-linux-gnu:$(GCC_VERSION)
	-docker pull $(DOCKER_USER)/gcc-$(1)-w64-mingw32:$(GCC_VERSION)
	-docker pull $(DOCKER_USER)/wine-$(1):latest
	docker build -f $$< \
	  --cache-from=$(DOCKER_USER)/wine-$(1):latest \
	  -t $(DOCKER_USER)/wine-$(1):latest \
	  build
push-wine-$(1)::
	-docker push $(DOCKER_USER)/wine-$(1):latest
push:: push-wine-$(1)
endef

$(eval $(call create-wine-rules,i686))
$(eval $(call create-wine-rules,x86_64))

define create-devel-rules
.PHONY: devel-$(1)
all devel: devel-$(1)
devel-$(1): BASE_IMAGE = $(DOCKER_USER)/wine-$(1):latest
devel-$(1): devel-$(1).Dockerfile
	rm -rf build; mkdir -p build
	-docker pull $(DOCKER_USER)/wine-$(1):latest
	-docker pull $(DOCKER_USER)/devel-$(1):latest
	docker build -f $$< \
	  --cache-from=$(DOCKER_USER)/devel-$(1):latest \
	  -t $(DOCKER_USER)/devel-$(1):latest \
	  build
push-devel-$(1)::
	-docker push $(DOCKER_USER)/devel-$(1):latest
push:: push-devel-$(1)
endef

$(eval $(call create-devel-rules,i686))
$(eval $(call create-devel-rules,x86_64))
