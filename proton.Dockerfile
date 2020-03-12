ARG BASE_IMAGE
FROM $BASE_IMAGE
RUN apt-get update && apt-get install -y \
  flex \
  libcapi20-dev \
  libgmp-dev \
  libgphoto2-2-dev \
  libgsm1-dev \
  libhal-dev \
  libmpc-dev \
  libmpfr-dev \
  libmpg123-dev \
  libosmesa6-dev \
  libpcap-dev \
  libsane-dev \
  libv4l-dev \
  libvulkan-dev \
  libxslt1-dev \
  nasm \
  yasm \
  ccache \
&& rm -rf /var/lib/apt/lists/*; \
:
ARG BISON_VERSION
RUN wget -qO- https://ftp.gnu.org/gnu/bison/bison-$BISON_VERSION.tar.xz | tar xJf - -C /tmp \
&& cd /tmp/bison-$BISON_VERSION \
&& ./configure --quiet \
  --prefix=/usr \
  MAKEINFO=true \
  CFLAGS=-fuse-ld=gold \
&& make -j8 MAKEINFO=true && make -j8 MAKEINFO=true install \
&& rm -rf /tmp/bison-$BISON_VERSION \
;
ARG ARCH
ARG BINUTILS_VERSION
RUN wget -qO- https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.gz | tar xzf - -C /tmp \
&& cd /tmp/binutils-$BINUTILS_VERSION \
&& ./configure --quiet \
  --prefix=/usr \
  --target=$ARCH-w64-mingw32 \
  --enable-lto \
  --enable-gold \
  --enable-ld=default \
  --enable-plugins \
  --enable-deterministic-archives \
  --disable-multilib \
  --disable-nls \
  --disable-werror \
  MAKEINFO=true \
&& make -j8 MAKEINFO=true && make -j8 MAKEINFO=true install \
&& rm -rf /tmp/binutils-$BINUTILS_VERSION \
;
ARG MINGW_VERSION
RUN wget -qO- https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-$MINGW_VERSION.tar.bz2 | tar xjf - -C /tmp \
&& cd /tmp/mingw-w64-$MINGW_VERSION/mingw-w64-headers \
&& ./configure --quiet \
  --prefix=/usr/$ARCH-w64-mingw32/ \
  --host=$ARCH-w64-mingw32 \
  --enable-sdk=all \
  --enable-secure-api \
  --enable-idl \
  MAKEINFO=true \
&& make -j8 MAKEINFO=true && make -j8 MAKEINFO=true install \
;
ARG GCC_VERSION
RUN wget -qO- https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz | tar xJf - -C /tmp \
&& mkdir /tmp/gcc-$GCC_VERSION/build && cd /tmp/gcc-$GCC_VERSION/build \
&& ../configure --quiet \
  --prefix=/usr \
  --target=$ARCH-w64-mingw32 \
  --with-native-system-header-dir="/i686-w64-mingw32/include" \
  --enable-languages=c \
  --enable-threads=posix \
  --disable-bootstrap \
  --disable-multilib \
  --disable-stage1-checking \
  --disable-checking \
  --disable-nls \
  --disable-lto \
  --disable-sjlj-exceptions \
  --with-dwarf2 \
  --with-system-zlib \
  --with-system-gmp \
  --with-system-mpfr \
  --with-system-mpc \
  MAKEINFO=true \
&& make -j8 MAKEINFO=true all-gcc && make -j8 MAKEINFO=true install-gcc \
&& rm -rf /tmp/gcc-$GCC_VERSION \
;
RUN wget -qO- https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-$MINGW_VERSION.tar.bz2 | tar xjf - -C /tmp \
&& cd /tmp/mingw-w64-$MINGW_VERSION/mingw-w64-crt \
&& ./configure --quiet \
  --prefix=/usr/$ARCH-w64-mingw32/ \
  --host=$ARCH-w64-mingw32 \
  --enable-wildcard \
  MAKEINFO=true \
&& make -j8 MAKEINFO=true && make -j8 MAKEINFO=true install \
&& rm -rf /tmp/mingw-w64-$MINGW_VERSION \
;
RUN wget -qO- https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-$MINGW_VERSION.tar.bz2 | tar xjf - -C /tmp \
&& cd /tmp/mingw-w64-$MINGW_VERSION/mingw-w64-libraries/winpthreads \
&& ./configure --quiet \
  --prefix=/usr/$ARCH-w64-mingw32/ \
  --host=$ARCH-w64-mingw32 \
  MAKEINFO=true \
&& make -j8 MAKEINFO=true && make -j8 MAKEINFO=true install \
&& rm -rf /tmp/mingw-w64-$MINGW_VERSION \
;
RUN wget -qO- https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz | tar xJf - -C /tmp \
&& mkdir /tmp/gcc-$GCC_VERSION/build && cd /tmp/gcc-$GCC_VERSION/build \
&& ../configure --quiet \
  --prefix=/usr \
  --target=$ARCH-w64-mingw32 \
  --enable-languages=c,c++,lto \
  --enable-threads=posix \
  --enable-lto \
  --disable-bootstrap \
  --disable-multilib \
  --disable-stage1-checking \
  --disable-checking \
  --disable-nls \
  --disable-sjlj-exceptions \
  --with-dwarf2 \
  --with-system-zlib \
  --with-system-gmp \
  --with-system-mpfr \
  --with-system-mpc \
  MAKEINFO=true \
&& make -j8 MAKEINFO=true && make -j8 MAKEINFO=true install \
&& rm -rf /tmp/gcc-$GCC_VERSION \
;
RUN wget -qO- https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.gz | tar xzf - -C /tmp \
&& cd /tmp/binutils-$BINUTILS_VERSION \
&& ./configure --quiet \
  --prefix=/usr \
  --host=$ARCH-linux-gnu \
  --build=$ARCH-linux-gnu \
  --target=$ARCH-linux-gnu \
  --enable-lto \
  --enable-gold \
  --enable-ld=default \
  --enable-plugins \
  --enable-deterministic-archives \
  --disable-multilib \
  --disable-nls \
  --disable-werror \
  MAKEINFO=true \
&& make -j8 MAKEINFO=true && make -j8 MAKEINFO=true install \
&& rm -rf /tmp/binutils-$BINUTILS_VERSION \
;
RUN wget -qO- https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz | tar xJf - -C /tmp \
&& mkdir /tmp/gcc-$GCC_VERSION/build && cd /tmp/gcc-$GCC_VERSION/build \
&& ../configure --quiet \
  --prefix=/usr \
  --host=$ARCH-linux-gnu \
  --build=$ARCH-linux-gnu \
  --target=$ARCH-linux-gnu \
  --enable-languages=c,c++,lto \
  --enable-lto \
  --disable-bootstrap \
  --disable-multilib \
  --disable-stage1-checking \
  --disable-checking \
  --disable-nls \
  --with-dwarf2 \
  --with-system-zlib \
  --with-system-gmp \
  --with-system-mpfr \
  --with-system-mpc \
  MAKEINFO=true \
&& make -j8 MAKEINFO=true && make -j8 MAKEINFO=true install \
&& rm -rf /tmp/gcc-$GCC_VERSION \
;
RUN bash -c 'ls /usr/bin/{,*-}{gcc,g++}{,-[0-9]*} | sed -re s:/bin:/lib/ccache: | xargs -n1 ln -sf ../../bin/ccache'
CMD ["/bin/bash"]
