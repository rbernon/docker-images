ARG ARCH
ARG BINUTILS_VERSION
ARG MINGW_VERSION
FROM rbernon/binutils-$ARCH-w64-mingw32:$BINUTILS_VERSION AS binutils
FROM rbernon/mingw-headers-$ARCH:$MINGW_VERSION AS mingw-headers
FROM rbernon/build-base-$ARCH:latest AS build

ARG ARCH
ARG GCC_VERSION
RUN wget -qO- http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz | tar xJf - -C /tmp
COPY --from=binutils      /opt/usr /usr
COPY --from=mingw-headers /opt/usr /usr
RUN mkdir /tmp/gcc-$GCC_VERSION/build && cd /tmp/gcc-$GCC_VERSION/build \
&& ../configure --quiet \
  --prefix=/usr \
  --libdir=/usr/lib \
  --libexecdir=/usr/lib \
  --host=$ARCH-linux-gnu \
  --build=$ARCH-linux-gnu \
  --target=$ARCH-w64-mingw32 \
  --program-prefix=$ARCH-w64-mingw32- \
  --enable-languages=c \
  --disable-bootstrap \
  --disable-checking \
  --disable-multilib \
  --disable-nls \
  --disable-shared \
  --disable-threads \
  --disable-werror \
  --with-system-gmp \
  --with-system-isl \
  --with-system-mpc \
  --with-system-mpfr \
  --with-system-zlib \
  MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true CFLAGS="-static --static" LDFLAGS="-s -static --static" all-gcc \
&& make --quiet -j8 MAKEINFO=true CFLAGS="-static --static" LDFLAGS="-s -static --static" install-strip-gcc DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/gcc-$GCC_VERSION
