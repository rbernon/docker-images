ARG ARCH
ARG TARGET
ARG BINUTILS_VERSION
ARG MINGW_VERSION
FROM rbernon/binutils-$ARCH-$TARGET:$BINUTILS_VERSION AS binutils
FROM rbernon/mingw-headers-$ARCH:$MINGW_VERSION AS mingw-headers
FROM rbernon/mingw-crt-$ARCH:$MINGW_VERSION AS mingw-crt
FROM rbernon/mingw-pthreads-$ARCH:$MINGW_VERSION AS mingw-pthreads
FROM rbernon/build-base-$ARCH:latest AS build

ARG ARCH
ARG TARGET
ARG GCC_VERSION
RUN wget -qO- http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz | tar xJf - -C /tmp
COPY --from=binutils       /opt/usr /usr
COPY --from=mingw-headers  /opt/usr /usr
COPY --from=mingw-crt      /opt/usr /usr
COPY --from=mingw-pthreads /opt/usr /usr
RUN mkdir /tmp/gcc-$GCC_VERSION/build && cd /tmp/gcc-$GCC_VERSION/build \
&& ../configure --quiet \
  --prefix=/usr \
  --libdir=/usr/lib \
  --libexecdir=/usr/lib \
  --host=$ARCH-linux-gnu \
  --build=$ARCH-linux-gnu \
  --target=$ARCH-$TARGET \
  --program-prefix=$ARCH-$TARGET- \
  --enable-languages=c,c++,lto \
  --enable-libstdcxx-time=yes \
  --enable-lto \
  --enable-threads=posix \
  --disable-bootstrap \
  --disable-checking \
  --disable-multilib \
  --disable-nls \
  --disable-plugin \
  --disable-shared \
  --disable-sjlj-exceptions \
  --disable-werror \
  --with-arch=nocona \
  --with-default-libstdcxx-abi=new \
  --with-dwarf2 \
  --with-system-gmp \
  --with-system-isl \
  --with-system-mpc \
  --with-system-mpfr \
  --with-system-zlib \
  --with-tune=core-avx2 \
  MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true CFLAGS="-static --static" LDFLAGS="-s -static --static" \
&& make --quiet -j8 MAKEINFO=true CFLAGS="-static --static" LDFLAGS="-s -static --static" install-strip DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/gcc-$GCC_VERSION
