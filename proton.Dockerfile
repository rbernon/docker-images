ARG BASE_IMAGE
FROM $BASE_IMAGE:latest
ARG ARCH
RUN wget -qO- https://more.musl.cc/$ARCH-linux-musl/$ARCH-w64-mingw32-cross.tgz | \
      tar xzf - --strip-components 2 -C /usr; \
:
RUN \
apt-get install -y gcc-5 g++-5 g++-5-multilib flex libosmesa6-dev libpcap-dev \
                   libhal-dev libsane-dev libv4l-dev libgphoto2-2-dev libcapi20-dev \
                   libgsm1-dev libmpg123-dev libvulkan-dev libxslt1-dev nasm yasm ccache; \
update-alternatives --install "$(command -v gcc)" gcc "$(command -v gcc-5)" 50; \
update-alternatives --set gcc "$(command -v gcc-5)"; \
update-alternatives --install "$(command -v g++)" g++ "$(command -v g++-5)" 50; \
update-alternatives --set g++ "$(command -v g++-5)"; \
update-alternatives --install "$(command -v cpp)" cpp-bin "$(command -v cpp-5)" 50; \
update-alternatives --set cpp-bin "$(command -v cpp-5)"; \
:
RUN wget -qO- https://ftp.gnu.org/gnu/bison/bison-3.5.tar.xz | \
      tar xJf - -C /tmp && cd /tmp/bison-3.5 && \
      ./configure --quiet --prefix=/usr CFLAGS=-fuse-ld=gold && \
      make && make install && \
      rm -rf /tmp/bison-3.5; \
:
CMD ["/bin/bash"]
