ARG ARCH
ARG BASE_IMAGE
ARG LIBISL_VERSION
ARG BINUTILS_VERSION
ARG MINGW_VERSION
ARG GCC_VERSION
FROM rbernon/libisl-$ARCH:$LIBISL_VERSION AS libisl
FROM rbernon/binutils-$ARCH-linux-gnu:$BINUTILS_VERSION AS binutils-linux
FROM rbernon/binutils-$ARCH-w64-mingw32:$BINUTILS_VERSION AS binutils-mingw
FROM rbernon/mingw-$ARCH:$MINGW_VERSION AS mingw
FROM rbernon/gcc-$ARCH-linux-gnu:$GCC_VERSION AS gcc-linux
FROM rbernon/gcc-$ARCH-w64-mingw32:$GCC_VERSION AS gcc-mingw
FROM $BASE_IMAGE AS base
RUN apt-get update && apt-get install -y \
  flex \
  libmpc2 \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /var/lib/apt/lists/*

FROM base AS bison
COPY --from=libisl         /usr /usr
COPY --from=binutils-linux /usr /usr
COPY --from=gcc-linux      /usr /usr
ARG ARCH
ARG BISON_VERSION
RUN wget -qO- https://ftp.gnu.org/gnu/bison/bison-$BISON_VERSION.tar.xz | tar xJf - -C /tmp \
&& cd /tmp/bison-$BISON_VERSION \
&& ./configure --quiet \
  --prefix=/usr \
  --libdir=/usr/lib \
  --host=$ARCH-linux-gnu \
  --build=$ARCH-linux-gnu \
  --disable-nls \
  MAKEINFO=true || cat config.log \
&& make --quiet -j8 MAKEINFO=true \
&& make --quiet -j8 MAKEINFO=true install-strip DESTDIR=/opt \
&& rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
&& rm -rf /tmp/bison-$BISON_VERSION

FROM base AS ccache
COPY --from=libisl         /usr /usr
COPY --from=binutils-linux /usr /usr
COPY --from=gcc-linux      /usr /usr
ARG ARCH
ARG CCACHE_VERSION
RUN wget -qO- https://github.com/ccache/ccache/releases/download/v$CCACHE_VERSION/ccache-$CCACHE_VERSION.tar.xz | tar xJf - -C /tmp \
&& cd /tmp/ccache-$CCACHE_VERSION \
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
  libmpc2 \
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

COPY --from=libisl         /usr /usr
COPY --from=binutils-mingw /usr /usr
COPY --from=binutils-linux /usr /usr
COPY --from=mingw          /usr /usr
COPY --from=gcc-mingw      /usr /usr
COPY --from=gcc-linux      /usr /usr

COPY --from=bison          /opt/usr /usr
COPY --from=ccache         /opt/usr /usr

RUN bash -c 'ls /usr/bin/{,*-}{cc,c++,gcc,g++}{,-[0-9]*} | sed -re s:/bin:/lib/ccache: | xargs -n1 ln -sf ../../bin/ccache'

ARG ARCH
ARG RUST_VERSION
ENV RUSTUP_HOME=/opt/rust
RUN curl -sSf https://sh.rustup.rs | env CARGO_HOME=/opt/rust sh -s -- -y --no-modify-path --default-toolchain "$RUST_VERSION-$ARCH" \
&& rm -rf /opt/rust/toolchains/*/share/ \
&& bash -c 'ls /opt/rust/bin/* | xargs -n1 -I{} ln -sf {} /usr/bin/'

CMD ["/bin/bash"]
