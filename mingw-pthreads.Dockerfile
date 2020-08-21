ARG ARCH
ARG BINUTILS_VERSION
ARG MINGW_VERSION
FROM rbernon/binutils-$ARCH-w64-mingw32:$BINUTILS_VERSION AS binutils
FROM rbernon/mingw-headers-$ARCH:$MINGW_VERSION AS mingw-headers
FROM rbernon/mingw-gcc-$ARCH:$MINGW_VERSION AS mingw-gcc
FROM rbernon/mingw-crt-$ARCH:$MINGW_VERSION AS mingw-crt
FROM rbernon/build-base-$ARCH:latest AS build

ARG ARCH
ARG MINGW_VERSION
RUN wget -qO- https://github.com/mirror/mingw-w64/archive/v$MINGW_VERSION.tar.gz | tar xzf - -C /tmp
COPY --from=binutils      /opt/usr /usr
COPY --from=mingw-headers /opt/usr /usr
COPY --from=mingw-gcc     /opt/usr /usr
COPY --from=mingw-crt     /opt/usr /usr
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
