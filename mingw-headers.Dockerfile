ARG ARCH
FROM rbernon/build-base-$ARCH:latest AS build

ARG ARCH
ARG MINGW_VERSION
RUN wget -qO- https://github.com/mirror/mingw-w64/archive/v$MINGW_VERSION.tar.gz | tar xzf - -C /tmp
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
