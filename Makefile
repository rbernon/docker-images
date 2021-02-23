STEAMRT_VERSION = 0.20210126.1
STEAMRT_URLBASE = registry.gitlab.steamos.cloud

PROTONSDK_URLBASE = rbernon
PROTONSDK_VERSION = $(STEAMRT_VERSION)-0

DOCKER = docker

.PHONY: version
version:
	@echo $(STEAMRT_VERSION)

.PHONY: steamrt
all: steamrt
steamrt:
	-$(DOCKER) pull $(STEAMRT_URLBASE)/steamrt/soldier/sdk:$(STEAMRT_VERSION)
	docker tag $(STEAMRT_URLBASE)/steamrt/soldier/sdk:$(STEAMRT_VERSION) $(PROTONSDK_URLBASE)/steamrt:$(STEAMRT_VERSION)
	docker tag $(STEAMRT_URLBASE)/steamrt/soldier/sdk:$(STEAMRT_VERSION) $(PROTONSDK_URLBASE)/steamrt:latest
push-steamrt::
	-$(DOCKER) push $(PROTONSDK_URLBASE)/steamrt:$(STEAMRT_VERSION)
	-$(DOCKER) push $(PROTONSDK_URLBASE)/steamrt:latest

push:: push-steamrt

# this is just for building toolchain, as we do static builds it should
# not have any impact on the end result, but changing it will invalidate
# docker caches, so we need something that don't change much
BASE_IMAGE_i686 = i386/ubuntu:18.04
BASE_IMAGE_x86_64 = ubuntu:18.04

BINUTILS_VERSION = 2.36.1
GCC_VERSION = 10.2.0
MINGW_VERSION = 8.0.0
RUST_VERSION = 1.50.0
LLVM_VERSION = 11.0.0
LLVM_MINGW_VERSION = 11.0

IMAGES_VERSION = experimental

%.Dockerfile: %.Dockerfile.in
	sed -re 's!@PROTONSDK_URLBASE@!$(PROTONSDK_URLBASE)!g' \
	    -re 's!@BASE_IMAGE@!$(BASE_IMAGE)!g' \
	    -re 's!@BINUTILS_VERSION@!$(BINUTILS_VERSION)!g' \
	    -re 's!@GCC_VERSION@!$(GCC_VERSION)!g' \
	    -re 's!@MINGW_VERSION@!$(MINGW_VERSION)!g' \
	    -re 's!@RUST_VERSION@!$(RUST_VERSION)!g' \
	    -re 's!@LLVM_VERSION@!$(LLVM_VERSION)!g' \
	    -re 's!@LLVM_MINGW_VERSION@!$(LLVM_MINGW_VERSION)!g' \
	    $< >$@

%-i686.Dockerfile.in: %.Dockerfile.in
	sed -re 's!@ARCH@!i686!g' \
	    -re 's!@ARCH_BASE@!i386!g' \
	    -re 's!@ARCH_TINI@!i386!g' \
	    -re 's!@SIZEOF_VOIDP@!4!g' \
	    $< >$@

%-x86_64.Dockerfile.in: %.Dockerfile.in
	sed -re 's!@ARCH@!x86_64!g' \
	    -re 's!@ARCH_BASE@!x86_64!g' \
	    -re 's!@ARCH_TINI@!amd64!g' \
	    -re 's!@SIZEOF_VOIDP@!8!g' \
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
	-$(DOCKER) pull $(PROTONSDK_URLBASE)/build-base-$(1):latest
	$(DOCKER) build -f $$< \
	  --cache-from=$(PROTONSDK_URLBASE)/build-base-$(1):latest \
	  -t $(PROTONSDK_URLBASE)/build-base-$(1):latest \
	  build
push-build-base-$(1)::
	$(DOCKER) push $(PROTONSDK_URLBASE)/build-base-$(1):latest
push:: push-build-base-$(1)
endef

$(eval $(call create-build-base-rules,i686))
$(eval $(call create-build-base-rules,x86_64))

define create-binutils-rules
.PHONY: binutils-$(1)-$(2)
all binutils: binutils-$(1)-$(2)
binutils-$(1)-$(2): BASE_IMAGE = $(PROTONSDK_URLBASE)/build-base-$(1):latest
binutils-$(1)-$(2): binutils-$(1)-$(2).Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(PROTONSDK_URLBASE)/binutils-$(1)-$(2):$(BINUTILS_VERSION)
	$(DOCKER) build -f $$< \
	  --cache-from=$(PROTONSDK_URLBASE)/binutils-$(1)-$(2):$(BINUTILS_VERSION) \
	  -t $(PROTONSDK_URLBASE)/binutils-$(1)-$(2):$(BINUTILS_VERSION) \
	  -t $(PROTONSDK_URLBASE)/binutils-$(1)-$(2):latest \
	  build
push-binutils-$(1)-$(2)::
	-$(DOCKER) push $(PROTONSDK_URLBASE)/binutils-$(1)-$(2):$(BINUTILS_VERSION)
	-$(DOCKER) push $(PROTONSDK_URLBASE)/binutils-$(1)-$(2):latest
push:: push-binutils-$(1)-$(2)
endef

$(eval $(call create-binutils-rules,i686,w64-mingw32))
$(eval $(call create-binutils-rules,i686,linux-gnu))
$(eval $(call create-binutils-rules,x86_64,w64-mingw32))
$(eval $(call create-binutils-rules,x86_64,linux-gnu))

define create-mingw-llvm-rules
.PHONY: mingw-$(2)-$(1)
all llvm: mingw-$(2)-$(1)
mingw-$(2)-$(1): BASE_IMAGE = $(PROTONSDK_URLBASE)/build-base-$(1):latest
mingw-$(2)-$(1): mingw-$(2)-$(1).Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(PROTONSDK_URLBASE)/mingw-llvm-$(1):$(LLVM_VERSION)
	$(DOCKER) build -f $$< \
	  --cache-from=$(PROTONSDK_URLBASE)/mingw-$(2)-$(1):$(LLVM_VERSION) \
	  -t $(PROTONSDK_URLBASE)/mingw-$(2)-$(1):$(LLVM_VERSION) \
	  -t $(PROTONSDK_URLBASE)/mingw-$(2)-$(1):latest \
	  build
push-mingw-$(2)-$(1)::
	-$(DOCKER) push $(PROTONSDK_URLBASE)/mingw-$(2)-$(1):$(LLVM_VERSION)
	-$(DOCKER) push $(PROTONSDK_URLBASE)/mingw-$(2)-$(1):latest
push:: push-mingw-$(2)-$(1)
endef

$(eval $(call create-mingw-llvm-rules,i686,llvm))
$(eval $(call create-mingw-llvm-rules,x86_64,llvm))
$(eval $(call create-mingw-llvm-rules,i686,libcxx))
$(eval $(call create-mingw-llvm-rules,x86_64,libcxx))
$(eval $(call create-mingw-llvm-rules,i686,compiler-rt))
$(eval $(call create-mingw-llvm-rules,x86_64,compiler-rt))

define create-mingw-rules
.PHONY: mingw-$(2)-$(1)
all mingw: mingw-$(2)-$(1)
mingw-$(2)-$(1): BASE_IMAGE = $(PROTONSDK_URLBASE)/build-base-$(1):latest
mingw-$(2)-$(1): mingw-$(2)-$(1).Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(PROTONSDK_URLBASE)/mingw-$(2)-$(1):$(MINGW_VERSION)
	$(DOCKER) build -f $$< \
	  --cache-from=$(PROTONSDK_URLBASE)/mingw-$(2)-$(1):$(MINGW_VERSION) \
	  -t $(PROTONSDK_URLBASE)/mingw-$(2)-$(1):$(MINGW_VERSION) \
	  -t $(PROTONSDK_URLBASE)/mingw-$(2)-$(1):latest \
	  build
push-mingw-$(2)-$(1)::
	-$(DOCKER) push $(PROTONSDK_URLBASE)/mingw-$(2)-$(1):$(MINGW_VERSION)
	-$(DOCKER) push $(PROTONSDK_URLBASE)/mingw-$(2)-$(1):latest
push:: push-mingw-$(2)-$(1)
endef

$(eval $(call create-mingw-rules,i686,headers))
$(eval $(call create-mingw-rules,i686,gcc-$(GCC_VERSION)))
$(eval $(call create-mingw-rules,i686,crt))
$(eval $(call create-mingw-rules,i686,pthreads))
$(eval $(call create-mingw-rules,i686,widl))
$(eval $(call create-mingw-rules,x86_64,headers))
$(eval $(call create-mingw-rules,x86_64,gcc-$(GCC_VERSION)))
$(eval $(call create-mingw-rules,x86_64,crt))
$(eval $(call create-mingw-rules,x86_64,pthreads))
$(eval $(call create-mingw-rules,x86_64,widl))

mingw-gcc-$(GCC_VERSION).Dockerfile.in: mingw-gcc.Dockerfile.in
	cp $< $@

mingw-gcc-i686: mingw-gcc-$(GCC_VERSION)-i686
push-mingw-gcc-i686: push-mingw-gcc-$(GCC_VERSION)-i686

mingw-gcc-x86_64: mingw-gcc-$(GCC_VERSION)-x86_64
push-mingw-gcc-x86_64: push-mingw-gcc-$(GCC_VERSION)-x86_64

$(eval $(call create-mingw-rules,i686,headers-llvm))
$(eval $(call create-mingw-rules,x86_64,headers-llvm))
$(eval $(call create-mingw-rules,i686,crt-llvm))
$(eval $(call create-mingw-rules,i686,pthreads-llvm))
$(eval $(call create-mingw-rules,x86_64,crt-llvm))
$(eval $(call create-mingw-rules,x86_64,pthreads-llvm))

GCC_TARGET_FLAGS_w64-mingw32 = --disable-shared
GCC_TARGET_FLAGS_linux-gnu =

define create-gcc-rules
.PHONY: gcc-$(1)-$(2)
all gcc: gcc-$(1)-$(2)
gcc-$(1)-$(2): TARGET_FLAGS = $(GCC_TARGET_FLAGS_$(2))
gcc-$(1)-$(2): BASE_IMAGE = $(PROTONSDK_URLBASE)/build-base-$(1):latest
gcc-$(1)-$(2): gcc-$(1)-$(2).Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(PROTONSDK_URLBASE)/gcc-$(1)-$(2):$(GCC_VERSION)
	$(DOCKER) build -f $$< \
	  --cache-from=$(PROTONSDK_URLBASE)/gcc-$(1)-$(2):$(GCC_VERSION) \
	  -t $(PROTONSDK_URLBASE)/gcc-$(1)-$(2):$(GCC_VERSION) \
	  -t $(PROTONSDK_URLBASE)/gcc-$(1)-$(2):latest \
	  build
push-gcc-$(1)-$(2)::
	-$(DOCKER) push $(PROTONSDK_URLBASE)/gcc-$(1)-$(2):$(GCC_VERSION)
	-$(DOCKER) push $(PROTONSDK_URLBASE)/gcc-$(1)-$(2):latest
push:: push-gcc-$(1)-$(2)
endef

$(eval $(call create-gcc-rules,i686,linux-gnu))
$(eval $(call create-gcc-rules,x86_64,linux-gnu))
$(eval $(call create-gcc-rules,i686,w64-mingw32))
$(eval $(call create-gcc-rules,x86_64,w64-mingw32))

PROTON_BASE_IMAGE = $(PROTONSDK_URLBASE)/steamrt:$(STEAMRT_VERSION)

define create-proton-rules
.PHONY: proton
all: proton
proton: BASE_IMAGE = $(PROTON_BASE_IMAGE)
proton: proton.Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(PROTONSDK_URLBASE)/proton:$(PROTONSDK_VERSION)
	$(DOCKER) build -f $$< \
	  --cache-from=$(PROTONSDK_URLBASE)/proton:$(PROTONSDK_VERSION) \
	  -t $(PROTONSDK_URLBASE)/proton:$(PROTONSDK_VERSION) \
	  -t $(PROTONSDK_URLBASE)/proton:latest \
	  build
push-proton::
	-$(DOCKER) push $(PROTONSDK_URLBASE)/proton:$(PROTONSDK_VERSION)
	-$(DOCKER) push $(PROTONSDK_URLBASE)/proton:latest
push:: push-proton
endef

$(eval $(call create-proton-rules))

WINE_BASE_IMAGE_i686 = i386/debian:unstable
WINE_BASE_IMAGE_x86_64 = debian:unstable
WINE_BASE_IMAGE_llvm-i686 = i386/debian:unstable
WINE_BASE_IMAGE_llvm-x86_64 = debian:unstable

define create-wine-rules
.PHONY: wine-$(1)
all wine: wine-$(1)
wine-$(1): BASE_IMAGE = $(WINE_BASE_IMAGE_$(1))
wine-$(1): wine-$(1).Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(PROTONSDK_URLBASE)/wine-$(1):$(IMAGES_VERSION)
	$(DOCKER) build -f $$< \
	  --cache-from=$(PROTONSDK_URLBASE)/wine-$(1):$(IMAGES_VERSION) \
	  -t $(PROTONSDK_URLBASE)/wine-$(1):$(IMAGES_VERSION) \
	  -t $(PROTONSDK_URLBASE)/wine-$(1):latest \
	  build
push-wine-$(1)::
	-$(DOCKER) push $(PROTONSDK_URLBASE)/wine-$(1):$(IMAGES_VERSION)
	-$(DOCKER) push $(PROTONSDK_URLBASE)/wine-$(1):latest
push:: push-wine-$(1)
endef

$(eval $(call create-wine-rules,i686))
$(eval $(call create-wine-rules,x86_64))
$(eval $(call create-wine-rules,llvm-i686))
$(eval $(call create-wine-rules,llvm-x86_64))

define create-devel-rules
.PHONY: devel-$(1)
all devel: devel-$(1)
devel-$(1): BASE_IMAGE = $(PROTONSDK_URLBASE)/wine-$(1):$(IMAGES_VERSION)
devel-$(1): devel-$(1).Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(PROTONSDK_URLBASE)/devel-$(1):$(IMAGES_VERSION)
	$(DOCKER) build -f $$< \
	  --cache-from=$(PROTONSDK_URLBASE)/devel-$(1):$(IMAGES_VERSION) \
	  -t $(PROTONSDK_URLBASE)/devel-$(1):$(IMAGES_VERSION) \
	  -t $(PROTONSDK_URLBASE)/devel-$(1):latest \
	  build
push-devel-$(1)::
	-$(DOCKER) push $(PROTONSDK_URLBASE)/devel-$(1):$(IMAGES_VERSION)
	-$(DOCKER) push $(PROTONSDK_URLBASE)/devel-$(1):latest
push:: push-devel-$(1)
endef

$(eval $(call create-devel-rules,i686))
$(eval $(call create-devel-rules,x86_64))
