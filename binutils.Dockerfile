ARG ARCH
ARG BASE_IMAGE
ARG LIBISL_VERSION
FROM rbernon/libisl-$ARCH:$LIBISL_VERSION AS libisl
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
COPY --from=libisl /usr /usr

ARG ARCH
ARG TARGET
ARG BINUTILS_VERSION
RUN wget -qO- http://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz | tar xJf - -C /tmp \
&& cd /tmp/binutils-$BINUTILS_VERSION \
&& ./configure --quiet \
  --prefix=/usr \
  --libdir=/usr/lib \
  --host=$ARCH-linux-gnu \
  --build=$ARCH-linux-gnu \
  --target=$ARCH-$TARGET \
  --program-prefix=$ARCH-$TARGET- \
  --enable-gold \
  --enable-ld=default \
  --enable-lto \
  --enable-plugins \
  --enable-static \
  --disable-multilib \
  --disable-nls \
  --disable-shared \
  --disable-werror \
  --with-gmp \
  --with-isl \
  --with-mpc \
  --with-mpfr \
  --with-system-zlib \
  MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true install-strip DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/binutils-$BINUTILS_VERSION

FROM scratch AS target
COPY --from=build /opt/usr /usr
CMD ["/bin/bash"]
