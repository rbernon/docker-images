ARG ARCH
ARG BASE_IMAGE
ARG BINUTILS_VERSION
ARG MINGW_VERSION
ARG GCC_VERSION
FROM rbernon/binutils-$ARCH-linux-gnu:$BINUTILS_VERSION AS binutils-linux
FROM rbernon/binutils-$ARCH-w64-mingw32:$BINUTILS_VERSION AS binutils-mingw
FROM rbernon/mingw-headers-$ARCH:$MINGW_VERSION AS mingw-headers
FROM rbernon/mingw-crt-$ARCH:$MINGW_VERSION AS mingw-crt
FROM rbernon/mingw-pthreads-$ARCH:$MINGW_VERSION AS mingw-pthreads
FROM rbernon/mingw-widl-$ARCH:$MINGW_VERSION AS mingw-widl
FROM rbernon/gcc-$ARCH-linux-gnu:$GCC_VERSION AS gcc-linux
FROM rbernon/gcc-$ARCH-w64-mingw32:$GCC_VERSION AS gcc-mingw

FROM $BASE_IMAGE AS base
RUN apt-get update && apt-get install -y \
  autoconf \
  bison \
  ccache \
  curl \
  flex \
  gettext \
  libisl22 \
  libmpc3 \
  libmpfr6 \
  libasound2-dev \
  libcapi20-dev \
  libcups2-dev \
  libdbus-1-dev \
  libfaudio-dev \
  libfontconfig1-dev \
  libfreetype6-dev \
  libgettextpo-dev \
  libgl1-mesa-dev \
  libglu1-mesa-dev \
  libgmp-dev \
  libgnutls28-dev \
  libgphoto2-dev \
  libgsm1-dev \
  libgsm1-dev \
  libgstreamer-plugins-base1.0-dev \
  libjpeg-dev \
  libkrb5-dev \
  liblcms2-dev \
  libldap2-dev \
  libmpg123-dev \
  libncurses5-dev \
  libopenal-dev \
  libopencl-clang-dev \
  libosmesa6-dev \
  libpcap-dev \
  libpcap0.8-dev \
  libpng-dev \
  libpulse-dev \
  libsane-dev \
  libsdl2-dev \
  libssl-dev \
  libtiff-dev \
  libudev-dev \
  libusb-dev \
  libv4l-dev \
  libvkd3d-dev \
  libvulkan-dev \
  libx11-dev \
  libxcomposite-dev \
  libxcursor-dev \
  libxext-dev \
  libxfixes-dev \
  libxi-dev \
  libxinerama-dev \
  libxkbfile-dev \
  libxml2-dev \
  libxmu-dev \
  libxrandr-dev \
  libxrender-dev \
  libxslt1-dev \
  libxt-dev \
  libxxf86dga-dev \
  libxxf86vm-dev \
  oss4-dev \
  pkg-config \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /var/lib/apt/lists/*

COPY --from=binutils-linux /opt/usr /usr
COPY --from=binutils-mingw /opt/usr /usr
COPY --from=mingw-headers  /opt/usr /usr
COPY --from=mingw-crt      /opt/usr /usr
COPY --from=mingw-pthreads /opt/usr /usr
COPY --from=mingw-widl     /opt/usr /usr
COPY --from=gcc-linux      /opt/usr /usr
COPY --from=gcc-mingw      /opt/usr /usr

RUN bash -c 'mkdir -p /usr/lib/ccache && ls /usr/bin/{,*-}{cc,c++,gcc,g++}{,-[0-9]*} | sed -re s:/bin:/lib/ccache: | xargs -n1 ln -sf ../../bin/ccache'
CMD ["/bin/bash"]
