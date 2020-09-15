ARG BASE_IMAGE
FROM $BASE_IMAGE AS base
RUN apt-get update && apt-get install -y \
  autoconf \
  bzip2 \
  gcc \
  g++ \
  flex \
  make \
  libmpc-dev \
  libmpfr-dev \
  libz-dev \
  wget \
  xz-utils \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /var/lib/apt/lists/*

FROM base AS isl
ARG ARCH
ARG ISL_VERSION
RUN wget --no-check-certificate -qO- http://isl.gforge.inria.fr/isl-$ISL_VERSION.tar.xz | tar xJf - -C /tmp
RUN cd /tmp/isl-$ISL_VERSION \
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
&& rm -rf /tmp/isl-$ISL_VERSION

FROM base AS binutils-mingw
ARG ARCH
ARG BINUTILS_VERSION
RUN wget --no-check-certificate -qO- https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.gz | tar xzf - -C /tmp
COPY --from=isl /opt/usr /usr
RUN cd /tmp/binutils-$BINUTILS_VERSION \
&& ./configure --quiet \
  --prefix=/usr \
  --libdir=/usr/lib \
  --host=$ARCH-linux-gnu \
  --build=$ARCH-linux-gnu \
  --target=$ARCH-w64-mingw32 \
  --program-prefix=$ARCH-w64-mingw32- \
  --enable-gold \
  --enable-ld=default \
  --enable-lto \
  --enable-plugins \
  --enable-shared \
  --disable-multilib \
  --disable-nls \
  --disable-static \
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

FROM base AS mingw-headers
ARG ARCH
ARG MINGW_VERSION
RUN wget --no-check-certificate -qO- https://github.com/mirror/mingw-w64/archive/v$MINGW_VERSION.tar.gz | tar xzf - -C /tmp
RUN cd /tmp/mingw-w64-$MINGW_VERSION/mingw-w64-headers \
&& ./configure --quiet \
  --prefix=/usr/$ARCH-w64-mingw32/ \
  --host=$ARCH-w64-mingw32 \
  --enable-sdk=all \
  --enable-secure-api \
  --enable-idl \
  MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true install-strip DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/mingw-w64-$MINGW_VERSION

FROM base AS gcc-base-mingw
ARG ARCH
ARG GCC_VERSION
RUN wget --no-check-certificate -qO- https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz | tar xJf - -C /tmp
COPY --from=isl            /opt/usr /usr
COPY --from=binutils-mingw /opt/usr /usr
COPY --from=mingw-headers  /opt/usr /usr
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
  --with-native-system-header-dir="/$ARCH-w64-mingw32/include" \
  --with-system-gmp \
  --with-system-isl \
  --with-system-mpc \
  --with-system-mpfr \
  --with-system-zlib \
  MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true all-gcc \
&& make --quiet -j8 MAKEINFO=true install-strip-gcc DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/gcc-$GCC_VERSION

FROM base AS mingw-crt
ARG ARCH
ARG MINGW_VERSION
RUN wget --no-check-certificate -qO- https://github.com/mirror/mingw-w64/archive/v$MINGW_VERSION.tar.gz | tar xzf - -C /tmp
COPY --from=isl            /opt/usr /usr
COPY --from=binutils-mingw /opt/usr /usr
COPY --from=mingw-headers  /opt/usr /usr
COPY --from=gcc-base-mingw /opt/usr /usr
RUN cd /tmp/mingw-w64-$MINGW_VERSION/mingw-w64-crt \
&& ./configure --quiet \
  --prefix=/usr/$ARCH-w64-mingw32/ \
  --host=$ARCH-w64-mingw32 \
  --enable-wildcard \
  MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true install-strip DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/mingw-w64-$MINGW_VERSION

FROM base AS mingw-pthreads
ARG ARCH
ARG MINGW_VERSION
RUN wget --no-check-certificate -qO- https://github.com/mirror/mingw-w64/archive/v$MINGW_VERSION.tar.gz | tar xzf - -C /tmp
COPY --from=isl            /opt/usr /usr
COPY --from=binutils-mingw /opt/usr /usr
COPY --from=mingw-headers  /opt/usr /usr
COPY --from=gcc-base-mingw /opt/usr /usr
COPY --from=mingw-crt      /opt/usr /usr
RUN cd /tmp/mingw-w64-$MINGW_VERSION/mingw-w64-libraries/winpthreads \
&& ./configure --quiet \
  --prefix=/usr/$ARCH-w64-mingw32/ \
  --host=$ARCH-w64-mingw32 \
  --disable-shared \
  MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true install-strip DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/mingw-w64-$MINGW_VERSION

FROM base AS mingw-widl
ARG ARCH
ARG MINGW_VERSION
RUN wget --no-check-certificate -qO- https://github.com/mirror/mingw-w64/archive/v$MINGW_VERSION.tar.gz | tar xzf - -C /tmp
RUN cd /tmp/mingw-w64-$MINGW_VERSION/mingw-w64-tools/widl \
&& ./configure --quiet \
  --prefix=/usr \
  --host=$ARCH-linux-gnu \
  --build=$ARCH-linux-gnu \
  --target=$ARCH-w64-mingw32 \
  --program-prefix=$ARCH-w64-mingw32- \
  MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true LDFLAGS="-static" \
&& make --quiet -j8 MAKEINFO=true install-strip DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/mingw-w64-$MINGW_VERSION

FROM base AS gcc-mingw
ARG ARCH
ARG GCC_VERSION
RUN wget --no-check-certificate -qO- https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz | tar xJf - -C /tmp
COPY --from=isl            /opt/usr /usr
COPY --from=binutils-mingw /opt/usr /usr
COPY --from=mingw-headers  /opt/usr /usr
COPY --from=gcc-base-mingw /opt/usr /usr
COPY --from=mingw-crt      /opt/usr /usr
COPY --from=mingw-pthreads /opt/usr /usr
RUN mkdir /tmp/gcc-$GCC_VERSION/build && cd /tmp/gcc-$GCC_VERSION/build \
&& ../configure --quiet \
  --prefix=/usr \
  --libdir=/usr/lib \
  --libexecdir=/usr/lib \
  --host=$ARCH-linux-gnu \
  --build=$ARCH-linux-gnu \
  --target=$ARCH-w64-mingw32 \
  --program-prefix=$ARCH-w64-mingw32- \
  --enable-languages=c,c++,lto \
  --enable-libstdcxx-time=yes \
  --enable-lto \
  --enable-plugin \
  --enable-threads=posix \
  --disable-bootstrap \
  --disable-checking \
  --disable-multilib \
  --disable-nls \
  --disable-shared \
  --disable-sjlj-exceptions \
  --disable-werror \
  --with-arch=nocona \
  --with-default-libstdcxx-abi=new \
  --with-dwarf2 \
  --with-native-system-header-dir="/$ARCH-w64-mingw32/include" \
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

FROM base AS binutils-linux
ARG ARCH
ARG BINUTILS_VERSION
RUN wget --no-check-certificate -qO- https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.gz | tar xzf - -C /tmp
COPY --from=isl /opt/usr /usr
RUN cd /tmp/binutils-$BINUTILS_VERSION \
&& ./configure --quiet \
  --prefix=/usr \
  --libdir=/usr/lib \
  --host=$ARCH-linux-gnu \
  --build=$ARCH-linux-gnu \
  --target=$ARCH-linux-gnu \
  --enable-gold \
  --enable-ld=default \
  --enable-lto \
  --enable-plugins \
  --enable-shared \
  --disable-multilib \
  --disable-nls \
  --disable-static \
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

FROM base AS gcc-linux
ARG ARCH
ARG GCC_VERSION
RUN wget --no-check-certificate -qO- https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz | tar xJf - -C /tmp
COPY --from=isl            /opt/usr /usr
COPY --from=binutils-linux /opt/usr /usr
RUN mkdir /tmp/gcc-$GCC_VERSION/build && cd /tmp/gcc-$GCC_VERSION/build \
&& ../configure --quiet \
  --prefix=/usr \
  --libdir=/usr/lib \
  --libexecdir=/usr/lib \
  --host=$ARCH-linux-gnu \
  --build=$ARCH-linux-gnu \
  --target=$ARCH-linux-gnu \
  --enable-languages=c,c++,lto \
  --enable-libstdcxx-time=yes \
  --enable-lto \
  --enable-plugin \
  --enable-threads=posix \
  --disable-bootstrap \
  --disable-checking \
  --disable-multilib \
  --disable-nls \
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
&& make --quiet -j8 MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true install-strip DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/gcc-$GCC_VERSION

FROM base AS bison
ARG ARCH
ARG BISON_VERSION
RUN wget --no-check-certificate -qO- https://ftp.gnu.org/gnu/bison/bison-$BISON_VERSION.tar.xz | tar xJf - -C /tmp
COPY --from=isl            /opt/usr /usr
COPY --from=binutils-linux /opt/usr /usr
COPY --from=gcc-linux      /opt/usr /usr
RUN cd /tmp/bison-$BISON_VERSION \
&& ./configure --quiet \
  --prefix=/usr \
  --libdir=/usr/lib \
  --host=$ARCH-linux-gnu \
  --build=$ARCH-linux-gnu \
  --disable-nls \
  MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true install-strip DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/bison-$BISON_VERSION

FROM base AS ccache
ARG ARCH
ARG CCACHE_VERSION
RUN wget --no-check-certificate -qO- https://github.com/ccache/ccache/releases/download/v$CCACHE_VERSION/ccache-$CCACHE_VERSION.tar.xz | tar xJf - -C /tmp
COPY --from=isl            /opt/usr /usr
COPY --from=binutils-linux /opt/usr /usr
COPY --from=gcc-linux      /opt/usr /usr
RUN cd /tmp/ccache-$CCACHE_VERSION \
&& ./configure --quiet \
  --prefix=/usr \
  --libdir=/usr/lib \
  --host=$ARCH-linux-gnu \
  --build=$ARCH-linux-gnu \
  MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true install DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/ccache-$CCACHE_VERSION

FROM base AS target
RUN apt-get update && apt-get install -y \
  flex \
  libcapi20-dev \
  libgmp-dev \
  libgphoto2-2-dev \
  libgsm1-dev \
  libhal-dev \
  libmpg123-dev \
  libosmesa6-dev \
  libpcap-dev \
  libsane-dev \
  libv4l-dev \
  libvulkan-dev \
  libxslt1-dev \
  nasm \
  yasm \
  ||: \
&& rm -rf /var/lib/apt/lists/*

COPY --from=isl            /opt/usr /usr
COPY --from=binutils-mingw /opt/usr /usr
COPY --from=mingw-headers  /opt/usr /usr
COPY --from=mingw-crt      /opt/usr /usr
COPY --from=mingw-pthreads /opt/usr /usr
COPY --from=mingw-widl     /opt/usr /usr
COPY --from=gcc-mingw      /opt/usr /usr
COPY --from=binutils-linux /opt/usr /usr
COPY --from=gcc-linux      /opt/usr /usr
COPY --from=bison          /opt/usr /usr
COPY --from=ccache         /opt/usr /usr

ARG ARCH
ARG GCC_VERSION
RUN bash -c 'mkdir -p /usr/lib/bfd-plugins/ && cp /usr/lib/gcc/$ARCH-linux-gnu/$GCC_VERSION/liblto_plugin*.so* /usr/lib/bfd-plugins/'
RUN bash -c 'ls /usr/bin/{,*-}{cc,c++,gcc,g++}{,-[0-9]*} | sed -re s:/bin:/lib/ccache: | xargs -n1 ln -sf ../../bin/ccache'

ARG ARCH
ARG RUST_VERSION
ENV RUSTUP_HOME=/opt/rust
RUN curl -sSf https://sh.rustup.rs | env CARGO_HOME=/opt/rust sh -s -- -y --no-modify-path --default-toolchain "$RUST_VERSION-$ARCH"
RUN bash -c 'ls /opt/rust/bin/* | xargs -n1 -I{} ln -sf {} /usr/bin/'

CMD ["/bin/bash"]
