STEAMRT_VERSION = $(shell cat $(HOME)/.steam/root/ubuntu12_32/steam-runtime/version.txt | tr '_' ' ' | awk '{print $$2}')
STEAMRT_URLBASE = http://repo.steampowered.com/steamrt-images-scout/snapshots/$(STEAMRT_VERSION)
STEAMRT_SDKBASE = com.valvesoftware.SteamRuntime.Sdk

all steamrt: docker-steamrt-amd64 docker-steamrt-i386
all proton: docker-proton-amd64 docker-proton-i386
all wine: docker-wine-amd64 docker-wine-i386

version:
	@echo $(STEAMRT_VERSION)

$(STEAMRT_SDKBASE)-%:
	wget $(STEAMRT_URLBASE)/$(STEAMRT_SDKBASE)-$* -O $@
steam-runtime.tar.xz:
	wget $(STEAMRT_URLBASE)/steam-runtime.tar.xz -O $@

docker-steamrt-amd64: $(STEAMRT_SDKBASE)-amd64,i386-scout-sysroot.Dockerfile $(STEAMRT_SDKBASE)-amd64,i386-scout-sysroot.tar.gz
	rm -rf build; mkdir -p build
	cp $(STEAMRT_SDKBASE)-amd64,i386-scout-sysroot.tar.gz build
	docker build -f $< -t rbernon/steamrt-amd64:$(STEAMRT_VERSION) build
	docker tag rbernon/steamrt-amd64:$(STEAMRT_VERSION) rbernon/steamrt-amd64:latest
	docker push rbernon/steamrt-amd64:$(STEAMRT_VERSION)
	docker push rbernon/steamrt-amd64:latest
.PHONY: docker-steamrt-amd64

docker-steamrt-i386: $(STEAMRT_SDKBASE)-i386-scout-sysroot.Dockerfile $(STEAMRT_SDKBASE)-i386-scout-sysroot.tar.gz
	rm -rf build; mkdir -p build
	cp $(STEAMRT_SDKBASE)-amd64,i386-scout-sysroot.tar.gz build
	docker build -f $< -t rbernon/steamrt-i386:$(STEAMRT_VERSION) .
	docker tag rbernon/steamrt-i386:$(STEAMRT_VERSION) rbernon/steamrt-i386:latest
	docker push rbernon/steamrt-i386:$(STEAMRT_VERSION)
	docker push rbernon/steamrt-i386:latest
.PHONY: docker-steamrt-i386

docker-proton-amd64: proton.Dockerfile docker-steamrt-amd64
	rm -rf build; mkdir -p build
	docker build -f $< \
	  --build-arg=ARCH=x86_64 \
	  --build-arg=BASE_IMAGE=rbernon/steamrt-amd64 \
	  -t rbernon/proton-amd64:$(STEAMRT_VERSION) \
	  build
	docker tag rbernon/proton-amd64:$(STEAMRT_VERSION) rbernon/proton-amd64:latest
	docker push rbernon/proton-amd64:$(STEAMRT_VERSION)
	docker push rbernon/proton-amd64:latest
.PHONY: docker-proton-amd64

docker-proton-i386: proton.Dockerfile docker-steamrt-i386
	rm -rf build; mkdir -p build
	docker build -f $< \
	  --build-arg=ARCH=i686 \
	  --build-arg=BASE_IMAGE=rbernon/steamrt-i386 \
	  -t rbernon/proton-i386:$(STEAMRT_VERSION) \
	  build
	docker tag rbernon/proton-i386:$(STEAMRT_VERSION) rbernon/proton-i386:latest
	docker push rbernon/proton-i386:$(STEAMRT_VERSION)
	docker push rbernon/proton-i386:latest
.PHONY: docker-proton-i386

docker-proton-build: proton-build.Dockerfile steam-runtime.tar.xz
	rm -rf build; mkdir -p build
	cp steam-runtime.tar.xz build
	docker build -f $< -t rbernon/proton-build:$(STEAMRT_VERSION) build
	docker tag rbernon/proton-build:$(STEAMRT_VERSION) rbernon/proton-build:latest
	docker push rbernon/proton-build:$(STEAMRT_VERSION)
	docker push rbernon/proton-build:latest
.PHONY: docker-proton-build

docker-wine-amd64: wine.Dockerfile
	rm -rf build; mkdir -p build
	docker build -f $< \
	  --build-arg=BASE_IMAGE=debian \
	  -t rbernon/wine-amd64:latest \
	  build
	docker push rbernon/wine-amd64:latest
.PHONY: docker-wine-amd64

docker-wine-i386: wine.Dockerfile
	rm -rf build; mkdir -p build
	docker build -f $< \
	  --build-arg=BASE_IMAGE=i386/debian\
	   -t rbernon/wine-i386:latest \
	   build
	docker push rbernon/wine-i386:latest
.PHONY: docker-wine-i386
