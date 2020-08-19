ARG ARCH
ARG BASE_IMAGE
ARG LIBISL_VERSION
ARG BINUTILS_VERSION
FROM rbernon/libisl-$ARCH:$LIBISL_VERSION AS libisl
FROM rbernon/binutils-$ARCH-w64-mingw32:$BINUTILS_VERSION AS binutils
FROM $BASE_IMAGE AS base
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

FROM base AS mingw-headers
ARG ARCH
ARG MINGW_VERSION
RUN wget --no-check-certificate -qO- https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v$MINGW_VERSION.tar.bz2 | tar xjf - -C /tmp \
&& cd /tmp/mingw-w64-v$MINGW_VERSION/mingw-w64-headers \
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
&& rm -rf /tmp/mingw-w64-v$MINGW_VERSION

FROM base AS mingw-gcc-base
COPY --from=mingw-headers  /opt/usr /usr
ARG ARCH
ARG GCC_VERSION
RUN wget -qO- http://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz | tar xJf - -C /tmp \
&& mkdir /tmp/gcc-$GCC_VERSION/build && cd /tmp/gcc-$GCC_VERSION/build \
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
&& make --quiet -j8 MAKEINFO=true all-gcc \
&& make --quiet -j8 MAKEINFO=true install-strip-gcc DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/gcc-$GCC_VERSION

FROM base AS mingw-crt
COPY --from=mingw-headers  /opt/usr /usr
COPY --from=mingw-gcc-base /opt/usr /usr
ARG ARCH
ARG MINGW_VERSION
RUN wget --no-check-certificate -qO- https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v$MINGW_VERSION.tar.bz2 | tar xjf - -C /tmp \
&& cd /tmp/mingw-w64-v$MINGW_VERSION/mingw-w64-crt \
&& ./configure --quiet \
  --prefix=/usr/$ARCH-w64-mingw32/ \
  --host=$ARCH-w64-mingw32 \
  --enable-wildcard \
  MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true install-strip DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/mingw-w64-v$MINGW_VERSION

FROM base AS mingw-pthreads
COPY --from=mingw-headers  /opt/usr /usr
COPY --from=mingw-gcc-base /opt/usr /usr
COPY --from=mingw-crt      /opt/usr /usr
ARG ARCH
ARG MINGW_VERSION
RUN wget --no-check-certificate -qO- https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v$MINGW_VERSION.tar.bz2 | tar xjf - -C /tmp \
&& cd /tmp/mingw-w64-v$MINGW_VERSION/mingw-w64-libraries/winpthreads \
&& ./configure --quiet \
  --prefix=/usr/$ARCH-w64-mingw32/ \
  --host=$ARCH-w64-mingw32 \
  --disable-shared \
  MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true install-strip DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/mingw-w64-v$MINGW_VERSION

FROM scratch AS target
COPY --from=mingw-headers  /opt/usr /usr
COPY --from=mingw-crt      /opt/usr /usr
COPY --from=mingw-pthreads /opt/usr /usr
CMD ["/bin/bash"]
