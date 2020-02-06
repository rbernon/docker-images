ARG BASE_IMAGE
FROM $BASE_IMAGE:sid
RUN apt-get update && apt-get install -y \
  autoconf \
  bison \
  ccache \
  flex \
  gcc \
  gettext \
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
  libgnutls28-dev \
  libgphoto2-dev \
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
  libpcap0.8-dev \
  libpng-dev \
  libpulse-dev \
  libsane-dev \
  libsdl2-dev \
  libssl-dev \
  libtiff-dev \
  libudev-dev \
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
  make \
  mingw-w64 \
  oss4-dev \
  pkg-config \
&& rm -rf /var/lib/apt/lists/* \
:
CMD ["/bin/bash"]
