ARG BASE_IMAGE
FROM $BASE_IMAGE AS build
RUN apt-get update && apt-get install -y \
  bzip2 \
  gcc \
  g++ \
  libgmp-dev \
  libmpc-dev \
  libmpfr-dev \
  libz-dev \
  make \
  wget \
  xz-utils \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /var/lib/apt/lists/*

ARG ARCH
ARG TARGET
ARG LIBISL_VERSION
RUN wget -qO- http://isl.gforge.inria.fr/isl-$LIBISL_VERSION.tar.xz | tar xJf - -C /tmp \
&& cd /tmp/isl-$LIBISL_VERSION \
&& ./configure --quiet \
  --prefix=/usr \
  --libdir=/usr/lib \
  --host=$ARCH-linux-gnu \
  --build=$ARCH-linux-gnu \
  --enable-shared \
  --disable-static \
  MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true install-strip DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/isl-$LIBISL_VERSION

FROM scratch AS target
COPY --from=build /opt/usr /usr
CMD ["/bin/bash"]
