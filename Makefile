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

.PHONY: docker-proton-amd64
docker-proton-amd64: proton.Dockerfile docker-steamrt-amd64
	rm -rf build; mkdir -p build
	docker build -f $< \
	  --build-arg ARCH=x86_64 \
	  --build-arg BASE_IMAGE=rbernon/steamrt-amd64:$(STEAMRT_VERSION) \
	  --build-arg BINUTILS_VERSION=2.34 \
	  --build-arg BISON_VERSION=3.5 \
	  --build-arg CCACHE_VERSION=3.7.9 \
	  --build-arg GCC_VERSION=9.3.0 \
	  --build-arg ISL_VERSION=0.22 \
	  --build-arg MINGW_VERSION=v7.0.0 \
	  -t rbernon/proton-amd64:$(STEAMRT_VERSION) \
	  -t rbernon/proton-amd64:latest \
	  build

.PHONY: docker-proton-i386
docker-proton-i386: proton.Dockerfile docker-steamrt-i386
	rm -rf build; mkdir -p build
	docker build -f $< \
	  --build-arg ARCH=i686 \
	  --build-arg BASE_IMAGE=rbernon/steamrt-i386:$(STEAMRT_VERSION) \
	  --build-arg BINUTILS_VERSION=2.34 \
	  --build-arg BISON_VERSION=3.5 \
	  --build-arg CCACHE_VERSION=3.7.9 \
	  --build-arg GCC_VERSION=9.3.0 \
	  --build-arg ISL_VERSION=0.22 \
	  --build-arg MINGW_VERSION=v7.0.0 \
	  -t rbernon/proton-i386:$(STEAMRT_VERSION) \
	  -t rbernon/proton-i386:latest \
	  build
