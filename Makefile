STEAMRT_VERSION = 0.20220329.0
STEAMRT_URLBASE = registry.gitlab.steamos.cloud

IMAGES_URLBASE = docker.io/rbernon
IMAGES_VERSION = $(STEAMRT_VERSION)-0

DOCKER = docker

.PHONY: version
version:
	@echo $(STEAMRT_VERSION)

.PHONY: steamrt
all: steamrt
steamrt:
	-$(DOCKER) pull $(STEAMRT_URLBASE)/steamrt/soldier/sdk:$(STEAMRT_VERSION)
	docker tag $(STEAMRT_URLBASE)/steamrt/soldier/sdk:$(STEAMRT_VERSION) $(IMAGES_URLBASE)/steamrt:$(STEAMRT_VERSION)
	docker tag $(STEAMRT_URLBASE)/steamrt/soldier/sdk:$(STEAMRT_VERSION) $(IMAGES_URLBASE)/steamrt:latest
push-steamrt::
	-$(DOCKER) push $(IMAGES_URLBASE)/steamrt:$(STEAMRT_VERSION)
	-$(DOCKER) push $(IMAGES_URLBASE)/steamrt:latest

push:: push-steamrt

# this is just for building toolchain, as we do static builds it should
# not have any impact on the end result, but changing it will invalidate
# docker caches, so we need something that don't change much
BASE_IMAGE_i686 = docker.io/i386/debian:10
BASE_IMAGE_x86_64 = docker.io/amd64/debian:10

BINUTILS_VERSION = 2.37
GCC_VERSION = 12.1.0
MINGW_VERSION = 10.0.0
RUST_VERSION = 1.61.0
LLVM_VERSION = 14.0.0

IMAGES_VERSION = experimental

BUILD_BASE_IMAGE_i686 = $(IMAGES_URLBASE)/build-base-i686:latest
BUILD_BASE_IMAGE_x86_64 = $(IMAGES_URLBASE)/build-base-x86_64:latest
BUILD_BASE_IMAGE_i686-linux-gnu = $(BUILD_BASE_IMAGE_i686)
BUILD_BASE_IMAGE_i686-w64-mingw32 = $(BUILD_BASE_IMAGE_i686)
BUILD_BASE_IMAGE_x86_64-linux-gnu = $(BUILD_BASE_IMAGE_x86_64)
BUILD_BASE_IMAGE_x86_64-w64-mingw32 = $(BUILD_BASE_IMAGE_x86_64)

%.Dockerfile: %.Dockerfile.in
	sed -re 's!@IMAGES_URLBASE@!$(IMAGES_URLBASE)!g' \
	    -re 's!@BASE_IMAGE@!$(BASE_IMAGE)!g' \
	    -re 's!@BINUTILS_VERSION@!$(BINUTILS_VERSION)!g' \
	    -re 's!@GCC_VERSION@!$(GCC_VERSION)!g' \
	    -re 's!@MINGW_VERSION@!$(MINGW_VERSION)!g' \
	    -re 's!@RUST_VERSION@!$(RUST_VERSION)!g' \
	    -re 's!@LLVM_VERSION@!$(LLVM_VERSION)!g' \
	    $< >$@

%-i686.Dockerfile.in: %.Dockerfile.in
	sed -re 's!@ARCH@!i686!g' \
	    -re 's!@ARCH_BASE@!i386!g' \
	    -re 's!@ARCH_TINI@!i386!g' \
	    -re 's!@ARCH_LLVM@!AArch64;ARM;RISCV;X86!g' \
	    -re 's!@SIZEOF_VOIDP@!4!g' \
	    $< >$@

%-x86_64.Dockerfile.in: %.Dockerfile.in
	sed -re 's!@ARCH@!x86_64!g' \
	    -re 's!@ARCH_BASE@!x86_64!g' \
	    -re 's!@ARCH_TINI@!amd64!g' \
	    -re 's!@ARCH_LLVM@!AArch64;ARM;RISCV;X86!g' \
	    -re 's!@SIZEOF_VOIDP@!8!g' \
	    $< >$@

%-linux-gnu.Dockerfile.in: %.Dockerfile.in
	sed -re 's!@TARGET@!linux-gnu!g' \
	    -re 's!@TARGET_SYSTEM@!Linux!g' \
	    -re 's!@TARGET_FLAGS@!$(TARGET_FLAGS)!g' \
	    $< >$@

%-w64-mingw32.Dockerfile.in: %.Dockerfile.in
	sed -re 's!@TARGET@!w64-mingw32!g' \
	    -re 's!@TARGET_SYSTEM@!Windows!g' \
	    -re 's!@TARGET_FLAGS@!$(TARGET_FLAGS)!g' \
	    $< >$@

define create-build-base-rules
.PHONY: build-base-$(1)
all build-base: build-base-$(1)
build-base-$(1): BASE_IMAGE = $(BASE_IMAGE_$(1))
build-base-$(1): build-base-$(1).Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(IMAGES_URLBASE)/build-base-$(1):latest
	$(DOCKER) build -f $$< \
	  --cache-from=$(IMAGES_URLBASE)/build-base-$(1):latest \
	  -t $(IMAGES_URLBASE)/build-base-$(1):latest \
	  build
push-build-base-$(1)::
	-$(DOCKER) push $(IMAGES_URLBASE)/build-base-$(1):latest
push:: push-build-base-$(1)
clean-build-base-$(1)::
	-$(DOCKER) image rm $(IMAGES_URLBASE)/build-base-$(1):latest
clean:: clean-build-base-$(1)
endef

$(eval $(call create-build-base-rules,i686))
$(eval $(call create-build-base-rules,x86_64))

define create-binutils-rules
.PHONY: binutils-$(1)-$(2)
all binutils: binutils-$(1)-$(2)
binutils-$(1)-$(2): BASE_IMAGE = $(BUILD_BASE_IMAGE_$(1))
binutils-$(1)-$(2): binutils-$(1)-$(2).Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(IMAGES_URLBASE)/binutils-$(1)-$(2):$(BINUTILS_VERSION)
	$(DOCKER) build -f $$< \
	  --cache-from=$(IMAGES_URLBASE)/binutils-$(1)-$(2):$(BINUTILS_VERSION) \
	  -t $(IMAGES_URLBASE)/binutils-$(1)-$(2):$(BINUTILS_VERSION) \
	  -t $(IMAGES_URLBASE)/binutils-$(1)-$(2):latest \
	  build
push-binutils-$(1)-$(2)::
	-$(DOCKER) push $(IMAGES_URLBASE)/binutils-$(1)-$(2):$(BINUTILS_VERSION)
	-$(DOCKER) push $(IMAGES_URLBASE)/binutils-$(1)-$(2):latest
push:: push-binutils-$(1)-$(2)
clean-binutils-$(1)-$(2)::
	-$(DOCKER) image rm $(IMAGES_URLBASE)/binutils-$(1)-$(2):$(BINUTILS_VERSION)
	-$(DOCKER) image rm $(IMAGES_URLBASE)/binutils-$(1)-$(2):latest
clean:: clean-binutils-$(1)-$(2)
endef

$(eval $(call create-binutils-rules,i686,w64-mingw32))
$(eval $(call create-binutils-rules,i686,linux-gnu))
$(eval $(call create-binutils-rules,x86_64,w64-mingw32))
$(eval $(call create-binutils-rules,x86_64,linux-gnu))

define create-llvm-rules
.PHONY: llvm$(2)-$(1)
all llvm: llvm$(2)-$(1)
llvm$(2)-$(1): BASE_IMAGE = $(BUILD_BASE_IMAGE_$(1))
llvm$(2)-$(1): llvm$(2)-$(1).Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(IMAGES_URLBASE)/llvm$(2)-$(1):$(LLVM_VERSION)
	$(DOCKER) build -f $$< \
	  --cache-from=$(IMAGES_URLBASE)/llvm$(2)-$(1):$(LLVM_VERSION) \
	  -t $(IMAGES_URLBASE)/llvm$(2)-$(1):$(LLVM_VERSION) \
	  -t $(IMAGES_URLBASE)/llvm$(2)-$(1):latest \
	  build
push-llvm$(2)-$(1)::
	-$(DOCKER) push $(IMAGES_URLBASE)/llvm$(2)-$(1):$(LLVM_VERSION)
	-$(DOCKER) push $(IMAGES_URLBASE)/llvm$(2)-$(1):latest
push:: push-llvm$(2)-$(1)
clean-llvm$(2)-$(1)::
	-$(DOCKER) image rm $(IMAGES_URLBASE)/llvm$(2)-$(1):$(LLVM_VERSION)
	-$(DOCKER) image rm $(IMAGES_URLBASE)/llvm$(2)-$(1):latest
clean:: clean-llvm$(2)-$(1)
endef

$(eval $(call create-llvm-rules,i686))
$(eval $(call create-llvm-rules,x86_64))

$(eval $(call create-llvm-rules,i686-linux-gnu,-base))
$(eval $(call create-llvm-rules,x86_64-linux-gnu,-base))
$(eval $(call create-llvm-rules,i686-w64-mingw32,-base))
$(eval $(call create-llvm-rules,x86_64-w64-mingw32,-base))

$(eval $(call create-llvm-rules,i686-linux-gnu,-libcxx))
$(eval $(call create-llvm-rules,x86_64-linux-gnu,-libcxx))
$(eval $(call create-llvm-rules,i686-w64-mingw32,-libcxx))
$(eval $(call create-llvm-rules,x86_64-w64-mingw32,-libcxx))

define create-mingw-rules
.PHONY: mingw-$(2)-$(1)
all mingw: mingw-$(2)-$(1)
mingw-$(2)-$(1): BASE_IMAGE = $(BUILD_BASE_IMAGE_$(1))
mingw-$(2)-$(1): mingw-$(2)-$(1).Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(IMAGES_URLBASE)/mingw-$(2)-$(1):$(MINGW_VERSION)
	$(DOCKER) build -f $$< \
	  --cache-from=$(IMAGES_URLBASE)/mingw-$(2)-$(1):$(MINGW_VERSION) \
	  -t $(IMAGES_URLBASE)/mingw-$(2)-$(1):$(MINGW_VERSION) \
	  -t $(IMAGES_URLBASE)/mingw-$(2)-$(1):latest \
	  build
push-mingw-$(2)-$(1)::
	-$(DOCKER) push $(IMAGES_URLBASE)/mingw-$(2)-$(1):$(MINGW_VERSION)
	-$(DOCKER) push $(IMAGES_URLBASE)/mingw-$(2)-$(1):latest
push:: push-mingw-$(2)-$(1)
clean-mingw-$(2)-$(1)::
	-$(DOCKER) image rm $(IMAGES_URLBASE)/mingw-$(2)-$(1):$(MINGW_VERSION)
	-$(DOCKER) image rm $(IMAGES_URLBASE)/mingw-$(2)-$(1):latest
clean:: clean-mingw-$(2)-$(1)
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
clean-mingw-gcc-i686: clean-mingw-gcc-$(GCC_VERSION)-i686

mingw-gcc-x86_64: mingw-gcc-$(GCC_VERSION)-x86_64
push-mingw-gcc-x86_64: push-mingw-gcc-$(GCC_VERSION)-x86_64
clean-mingw-gcc-x86_64: clean-mingw-gcc-$(GCC_VERSION)-x86_64

$(eval $(call create-mingw-rules,i686,headers-llvm))
$(eval $(call create-mingw-rules,x86_64,headers-llvm))
$(eval $(call create-mingw-rules,i686,crt-llvm))
$(eval $(call create-mingw-rules,x86_64,crt-llvm))

GCC_TARGET_FLAGS_w64-mingw32 = --disable-shared
GCC_TARGET_FLAGS_linux-gnu =

define create-gcc-rules
.PHONY: gcc-$(1)-$(2)
all gcc: gcc-$(1)-$(2)
gcc-$(1)-$(2): TARGET_FLAGS = $(GCC_TARGET_FLAGS_$(2))
gcc-$(1)-$(2): BASE_IMAGE = $(BUILD_BASE_IMAGE_$(1))
gcc-$(1)-$(2): gcc-$(1)-$(2).Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(IMAGES_URLBASE)/gcc-$(1)-$(2):$(GCC_VERSION)
	$(DOCKER) build -f $$< \
	  --cache-from=$(IMAGES_URLBASE)/gcc-$(1)-$(2):$(GCC_VERSION) \
	  -t $(IMAGES_URLBASE)/gcc-$(1)-$(2):$(GCC_VERSION) \
	  -t $(IMAGES_URLBASE)/gcc-$(1)-$(2):latest \
	  build
push-gcc-$(1)-$(2)::
	-$(DOCKER) push $(IMAGES_URLBASE)/gcc-$(1)-$(2):$(GCC_VERSION)
	-$(DOCKER) push $(IMAGES_URLBASE)/gcc-$(1)-$(2):latest
push:: push-gcc-$(1)-$(2)
clean-gcc-$(1)-$(2)::
	-$(DOCKER) image rm $(IMAGES_URLBASE)/gcc-$(1)-$(2):$(GCC_VERSION)
	-$(DOCKER) image rm $(IMAGES_URLBASE)/gcc-$(1)-$(2):latest
clean:: clean-gcc-$(1)-$(2)
endef

$(eval $(call create-gcc-rules,i686,linux-gnu))
$(eval $(call create-gcc-rules,x86_64,linux-gnu))
$(eval $(call create-gcc-rules,i686,w64-mingw32))
$(eval $(call create-gcc-rules,x86_64,w64-mingw32))

PROTON_BASE_IMAGE-base = $(IMAGES_URLBASE)/steamrt:$(STEAMRT_VERSION)
PROTON_BASE_IMAGE = $(IMAGES_URLBASE)/proton-base:$(IMAGES_VERSION)
PROTON_BASE_IMAGE-llvm = $(IMAGES_URLBASE)/proton-base:$(IMAGES_VERSION)

define create-proton-rules
.PHONY: proton$(1)
all: proton$(1)
proton$(1): BASE_IMAGE = $(PROTON_BASE_IMAGE$(1))
proton$(1): proton$(1).Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(IMAGES_URLBASE)/proton$(1):$(IMAGES_VERSION)
	$(DOCKER) build -f $$< \
	  --cache-from=$(IMAGES_URLBASE)/proton$(1):$(IMAGES_VERSION) \
	  -t $(IMAGES_URLBASE)/proton$(1):$(IMAGES_VERSION) \
	  -t $(IMAGES_URLBASE)/proton$(1):latest \
	  build
push-proton$(1)::
	-$(DOCKER) push $(IMAGES_URLBASE)/proton$(1):$(IMAGES_VERSION)
	-$(DOCKER) push $(IMAGES_URLBASE)/proton$(1):latest
push:: push-proton$(1)
clean-proton$(1)::
	-$(DOCKER) image rm $(IMAGES_URLBASE)/proton$(1):$(IMAGES_VERSION)
	-$(DOCKER) image rm $(IMAGES_URLBASE)/proton$(1):latest
clean:: clean-proton$(1)
endef

$(eval $(call create-proton-rules,-base))
$(eval $(call create-proton-rules,))
$(eval $(call create-proton-rules,-llvm))

WINE_BASE_IMAGE_base-i686 = docker.io/i386/debian:unstable
WINE_BASE_IMAGE_base-x86_64 = docker.io/amd64/debian:unstable
WINE_BASE_IMAGE_i686 = $(IMAGES_URLBASE)/wine-base-i686:$(IMAGES_VERSION)
WINE_BASE_IMAGE_x86_64 = $(IMAGES_URLBASE)/wine-base-x86_64:$(IMAGES_VERSION)
WINE_BASE_IMAGE_llvm-i686 = $(IMAGES_URLBASE)/wine-base-i686:$(IMAGES_VERSION)
WINE_BASE_IMAGE_llvm-x86_64 = $(IMAGES_URLBASE)/wine-base-x86_64:$(IMAGES_VERSION)

define create-wine-rules
.PHONY: wine-$(1)
all wine: wine-$(1)
wine-$(1): BASE_IMAGE = $(WINE_BASE_IMAGE_$(1))
wine-$(1): wine-$(1).Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(IMAGES_URLBASE)/wine-$(1):$(IMAGES_VERSION)
	$(DOCKER) build -f $$< \
	  --cache-from=$(IMAGES_URLBASE)/wine-$(1):$(IMAGES_VERSION) \
	  -t $(IMAGES_URLBASE)/wine-$(1):$(IMAGES_VERSION) \
	  -t $(IMAGES_URLBASE)/wine-$(1):latest \
	  build
push-wine-$(1)::
	-$(DOCKER) push $(IMAGES_URLBASE)/wine-$(1):$(IMAGES_VERSION)
	-$(DOCKER) push $(IMAGES_URLBASE)/wine-$(1):latest
push:: push-wine-$(1)
clean-wine-$(1)::
	-$(DOCKER) image rm $(IMAGES_URLBASE)/wine-$(1):$(IMAGES_VERSION)
	-$(DOCKER) image rm $(IMAGES_URLBASE)/wine-$(1):latest
clean:: clean-wine-$(1)
endef

$(eval $(call create-wine-rules,base-i686))
$(eval $(call create-wine-rules,base-x86_64))
$(eval $(call create-wine-rules,i686))
$(eval $(call create-wine-rules,x86_64))
$(eval $(call create-wine-rules,llvm-i686))
$(eval $(call create-wine-rules,llvm-x86_64))

define create-devel-rules
.PHONY: devel-$(1)
all devel: devel-$(1)
devel-$(1): BASE_IMAGE = $(IMAGES_URLBASE)/wine-$(1):$(IMAGES_VERSION)
devel-$(1): devel-$(1).Dockerfile
	rm -rf build; mkdir -p build
	-$(DOCKER) pull $(IMAGES_URLBASE)/devel-$(1):$(IMAGES_VERSION)
	$(DOCKER) build -f $$< \
	  --cache-from=$(IMAGES_URLBASE)/devel-$(1):$(IMAGES_VERSION) \
	  -t $(IMAGES_URLBASE)/devel-$(1):$(IMAGES_VERSION) \
	  -t $(IMAGES_URLBASE)/devel-$(1):latest \
	  build
push-devel-$(1)::
	-$(DOCKER) push $(IMAGES_URLBASE)/devel-$(1):$(IMAGES_VERSION)
	-$(DOCKER) push $(IMAGES_URLBASE)/devel-$(1):latest
push:: push-devel-$(1)
clean-devel-$(1)::
	-$(DOCKER) image rm $(IMAGES_URLBASE)/devel-$(1):$(IMAGES_VERSION)
	-$(DOCKER) image rm $(IMAGES_URLBASE)/devel-$(1):latest
clean:: clean-devel-$(1)
endef

$(eval $(call create-devel-rules,i686))
$(eval $(call create-devel-rules,x86_64))
