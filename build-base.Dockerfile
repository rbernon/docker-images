ARG ARCH
ARG BASE_IMAGE
FROM $BASE_IMAGE AS base
RUN apt-get update && apt-get install -y \
  autoconf \
  bzip2 \
  g++ \
  gcc \
  libgmp-dev \
  libisl-dev \
  libmpc-dev \
  libmpfr-dev \
  libtool \
  libz-dev \
  make \
  wget \
  xz-utils \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /var/lib/apt/lists/*
