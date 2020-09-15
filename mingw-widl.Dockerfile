ARG ARCH
FROM rbernon/build-base-$ARCH:latest AS build

ARG ARCH
ARG MINGW_VERSION
RUN wget -qO- https://github.com/mirror/mingw-w64/archive/v$MINGW_VERSION.tar.gz | tar xzf - -C /tmp
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
