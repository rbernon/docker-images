FROM debian:sid
ADD steam-runtime.tar.xz /opt
RUN apt-get update && apt-get install -y \
  make \
  python3-pip \
&& rm -rf /var/lib/apt/lists/* \
&& pip3 install -U afdko \
&& :
CMD ["/bin/bash"]
