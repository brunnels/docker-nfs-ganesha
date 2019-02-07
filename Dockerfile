# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Modified from https://github.com/rootfs/nfs-ganesha-docker by Huamin Chen
FROM fedora:28

# Build ganesha from source, installing deps and removing them in one line.
# Why?
# 1. Ignore (bind mounted) files in mount table, only present in >= V2.7.1 which is not yet packaged
# 2. Set NFS_V4_RECOV_ROOT to /export

RUN dnf install -y tar gcc cmake autoconf libtool bison flex make gcc-c++ krb5-devel dbus-devel jemalloc-devel libnfsidmap-devel libnsl2-devel patch && dnf clean all \
	&& curl -L https://github.com/nfs-ganesha/nfs-ganesha/archive/V2.7.1.tar.gz | tar zx \
	&& curl -L https://github.com/nfs-ganesha/ntirpc/archive/v1.7.1.tar.gz | tar zx \
	&& rm -r nfs-ganesha-2.7.1/src/libntirpc \
	&& mv ntirpc-1.7.1 nfs-ganesha-2.7.1/src/libntirpc \
	&& cd nfs-ganesha-2.7.1 \
	&& cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_CONFIG=vfs_only src/ \
	&& make \
	&& make install \
	&& cp src/scripts/ganeshactl/org.ganesha.nfsd.conf /etc/dbus-1/system.d/ \
	&& cd .. \
	&& rm -rf nfs-ganesha-2.7.1 \
	&& dnf remove -y tar gcc cmake autoconf libtool bison flex make gcc-c++ krb5-devel dbus-devel jemalloc-devel libnfsidmap-devel patch && dnf clean all

RUN dnf install -y dbus-x11 rpcbind hostname nfs-utils xfsprogs jemalloc libnfsidmap && dnf clean all

RUN mkdir -p /var/run/dbus
RUN mkdir -p /export

COPY nfs-ports.sysconfig /tmp/
RUN cat /tmp/nfs-ports.sysconfig > /etc/sysconfig/nfs; rm /tmp/nfs-ports.sysconfig;
EXPOSE 2049/tcp 2049/udp 30001/tcp 30001/udp 30002/tcp 30002/udp 30003/tcp 30003/udp 111/tcp 111/udp 875/tcp 875/udp

# Add startup script
COPY start.sh /

# Start Ganesha NFS daemon by default
CMD ["/start.sh"]
