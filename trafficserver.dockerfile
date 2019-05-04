FROM centos:7 as desenv

ARG ATS_VERSION=8.0.3
ARG LUAJIT_VERSION=2.0.5
ARG LUAROCKS_VERSION=3.0.4

ENV ATS_VERSION $ATS_VERSION
ENV container=docker

RUN yum clean all && yum update -y \
  && yum install nano less tree patch wget unzip bzip2 \
    # required
    autoconf automake libtool gcc gcc-c++ make pkgconfig pcre-devel tcl-devel expat-devel openssl openssl-devel \
    # recommended
    tcl tcl-devel pcre pcre-devel \
    libcap libcap-devel hwloc hwloc-devel ncurses ncurses-devel curl libcurl-devel \
    libunwind libunwind-devel flex hwloc hwloc-devel \
    telnet bind-utils net-tools lsof centos-release-scl -y \
  && yum install devtoolset-7 -y

COPY ./luasocket.patch /tmp/

RUN cd /tmp \ 
  && curl -fsSLO http://luajit.org/download/LuaJIT-${LUAJIT_VERSION}.tar.gz \
  && tar zxpf LuaJIT-${LUAJIT_VERSION}.tar.gz \
  && cd LuaJIT-${LUAJIT_VERSION} \
  && make -j$(getconf _NPROCESSORS_ONLN) && make install \
  && echo "$(find / -name libluajit-5.1.so.2 -printf '%h\n')" > /etc/ld.so.conf.d/libluajit-2.0.conf \
  && ldconfig

RUN set -xe \
  && cd /tmp \
  && curl -fsSLO http://www-us.apache.org/dist/trafficserver/trafficserver-${ATS_VERSION}.tar.bz2 \
  && tar -xf trafficserver-${ATS_VERSION}.tar.bz2 \
  && cd trafficserver-${ATS_VERSION} \
  && autoreconf -if \
  && scl enable devtoolset-7 "./configure --with-luajit=/usr/local" \
  && scl enable devtoolset-7 "make -j$(getconf _NPROCESSORS_ONLN) && make install"

RUN set -xe \
  && cd /tmp \
  && curl -fsSLO https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz \
  && tar zxpf luarocks-${LUAROCKS_VERSION}.tar.gz \
  && cd luarocks-${LUAROCKS_VERSION} \
  && ./configure --with-lua="/usr/local/" --with-lua-include="/usr/local/include/luajit-2.0" --force-config \
  && make build bootstrap

# installing luasocket and redis-lua using luarocks - easier to maintain
RUN set -xe \
  && luarocks install luasocket \
  && luarocks install redis-lua

# patch luasocket and manually build/install to replace it with a build that properly export symbols
RUN set -xe \
  && cd /tmp \
  && curl -fsSL https://github.com/diegonehab/luasocket/archive/v3.0-rc1.tar.gz -o luasocket.tar.gz \
  && tar zxpf luasocket.tar.gz \
  && cd luasocket-3.0-rc1 \
  && patch -p0 < /tmp/luasocket.patch \
  && make linux && make install 
  
RUN cd /tmp\
  && rm -rf /tmp/{trafficserver,LuaJIT,luarocks}* \
  && yum clean all && yum update -y

COPY ./config /usr/local/etc/trafficserver
COPY ./plugins /opt/lua-plugins/

EXPOSE 8080

CMD /usr/local/bin/traffic_manager
