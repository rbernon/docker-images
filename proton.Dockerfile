ARG BASE_IMAGE
ARG BINUTILS_VERSION
ARG MINGW_VERSION
ARG GCC_VERSION
FROM rbernon/binutils-i686-linux-gnu:$BINUTILS_VERSION AS binutils-linux-i686
FROM rbernon/binutils-x86_64-linux-gnu:$BINUTILS_VERSION AS binutils-linux-x86_64
FROM rbernon/binutils-i686-w64-mingw32:$BINUTILS_VERSION AS binutils-mingw-i686
FROM rbernon/binutils-x86_64-w64-mingw32:$BINUTILS_VERSION AS binutils-mingw-x86_64
FROM rbernon/mingw-headers-i686:$MINGW_VERSION AS mingw-headers-i686
FROM rbernon/mingw-headers-x86_64:$MINGW_VERSION AS mingw-headers-x86_64
FROM rbernon/mingw-crt-i686:$MINGW_VERSION AS mingw-crt-i686
FROM rbernon/mingw-crt-x86_64:$MINGW_VERSION AS mingw-crt-x86_64
FROM rbernon/mingw-pthreads-i686:$MINGW_VERSION AS mingw-pthreads-i686
FROM rbernon/mingw-pthreads-x86_64:$MINGW_VERSION AS mingw-pthreads-x86_64
FROM rbernon/mingw-widl-i686:$MINGW_VERSION AS mingw-widl-i686
FROM rbernon/mingw-widl-x86_64:$MINGW_VERSION AS mingw-widl-x86_64
FROM rbernon/gcc-i686-linux-gnu:$GCC_VERSION AS gcc-linux-i686
FROM rbernon/gcc-x86_64-linux-gnu:$GCC_VERSION AS gcc-linux-x86_64
FROM rbernon/gcc-i686-w64-mingw32:$GCC_VERSION AS gcc-mingw-i686
FROM rbernon/gcc-x86_64-w64-mingw32:$GCC_VERSION AS gcc-mingw-x86_64

FROM $BASE_IMAGE AS base
# RUN apt-get update && apt-get install -y \
#   flex \
#   libcapi20-dev \
#   libgmp-dev \
#   libgphoto2-2-dev \
#   libgsm1-dev \
#   libhal-dev \
#   libmpg123-dev \
#   libosmesa6-dev \
#   libpcap-dev \
#   libsane-dev \
#   libv4l-dev \
#   libvulkan-dev \
#   libxslt1-dev \
# && rm -rf /opt/usr/share/doc /opt/usr/share/info /opt/usr/share/man \
# && rm -rf /var/lib/apt/lists/*

COPY --from=binutils-linux-i686   /opt/usr /usr
COPY --from=binutils-linux-x86_64 /opt/usr /usr
COPY --from=binutils-mingw-i686   /opt/usr /usr
COPY --from=binutils-mingw-x86_64 /opt/usr /usr
COPY --from=mingw-headers-i686    /opt/usr /usr
COPY --from=mingw-headers-x86_64  /opt/usr /usr
COPY --from=mingw-crt-i686        /opt/usr /usr
COPY --from=mingw-crt-x86_64      /opt/usr /usr
COPY --from=mingw-pthreads-i686   /opt/usr /usr
COPY --from=mingw-pthreads-x86_64 /opt/usr /usr
COPY --from=mingw-widl-i686       /opt/usr /usr
COPY --from=mingw-widl-x86_64     /opt/usr /usr
COPY --from=gcc-linux-i686        /opt/usr /usr
COPY --from=gcc-linux-x86_64      /opt/usr /usr
COPY --from=gcc-mingw-i686        /opt/usr /usr
COPY --from=gcc-mingw-x86_64      /opt/usr /usr

ARG RUST_VERSION
ENV RUSTUP_HOME=/opt/rust
RUN curl -sSf https://sh.rustup.rs | env CARGO_HOME=/opt/rust sh -s -- -y --no-modify-path \
  --default-host "x86_64-unknown-linux-gnu" \
  --default-toolchain "$RUST_VERSION-x86_64-unknown-linux-gnu" \
  --target "i686-unknown-linux-gnu" \
&& bash -c 'ls /opt/rust/bin/* | xargs -n1 -I{} ln -sf {} /usr/bin/'

RUN bash -c 'mkdir -p /usr/lib/ccache && ls /usr/bin/{,*-}{cc,c++,gcc,g++}{,-[0-9]*} | sed -re s:/bin:/lib/ccache: | xargs -n1 ln -sf ../../bin/ccache'
ENV PATH=/usr/lib/ccache:$PATH
CMD ["/bin/bash"]
