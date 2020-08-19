ARG ARCH
ARG TARGET
ARG BASE_IMAGE
ARG LIBISL_VERSION
ARG BINUTILS_VERSION
ARG MINGW_VERSION
FROM rbernon/libisl-$ARCH:$LIBISL_VERSION AS libisl
FROM rbernon/binutils-$ARCH-$TARGET:$BINUTILS_VERSION AS binutils
FROM rbernon/mingw-$ARCH:$MINGW_VERSION AS mingw
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
COPY --from=libisl   /usr /usr
COPY --from=binutils /usr /usr
COPY --from=mingw    /usr /usr

ARG ARCH
ARG TARGET
ARG GCC_VERSION
RUN wget -qO- http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz | tar xJf - -C /tmp \
&& mkdir /tmp/gcc-$GCC_VERSION/build && cd /tmp/gcc-$GCC_VERSION/build \
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
  --enable-plugin \
  --enable-threads=posix \
  --enable-static \
  --disable-bootstrap \
  --disable-checking \
  --disable-multilib \
  --disable-nls \
  --disable-sjlj-exceptions \
  --disable-shared \
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
&& make --quiet -j8 MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true install-strip DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/gcc-$GCC_VERSION

FROM scratch AS target
COPY --from=build /opt/usr /usr
CMD ["/bin/bash"]
