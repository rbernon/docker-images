ARG ARCH
FROM rbernon/build-base-$ARCH:latest AS build

ARG ARCH
ARG TARGET
ARG BINUTILS_VERSION
RUN wget -qO- https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz | tar xJf - -C /tmp
RUN cd /tmp/binutils-$BINUTILS_VERSION \
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
  --enable-static \
  --disable-multilib \
  --disable-nls \
  --disable-plugins \
  --disable-shared \
  --disable-werror \
  --with-gmp \
  --with-isl \
  --with-mpc \
  --with-mpfr \
  --with-system-zlib \
  MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true configure-host \
&& make --quiet -j8 MAKEINFO=true LDFLAGS="-static" \
&& make --quiet -j8 MAKEINFO=true install-strip DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/binutils-$BINUTILS_VERSION
