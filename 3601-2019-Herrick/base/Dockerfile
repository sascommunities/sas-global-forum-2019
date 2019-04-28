FROM centos:7.3.1611

# - Move default shell from sh to bash
# - Update all packages
# - Install required packages
RUN rm /bin/sh \
	&& ln -s /bin/bash /bin/sh \
	&& yum update -y \
	&& yum install -y \
	gcc \
	libffi \
	libffi-devel \
	zlib-devel \
	bzip2-devel \
	openssl-devel \
	ncurses-devel \
	sqlite-devel \
	readline-devel \
	tk-devel \
	gdbm-devel \
	db4-devel \
	libpcap-devel \
	xz-devel \
	expat-devel \
	ca-certificates \
	numactl \
	wget \
	git \
	make

# Install SQLite
RUN cd /usr/src \
	&& wget http://www.sqlite.org/2017/sqlite-autoconf-3210000.tar.gz \
	&& tar xvfz sqlite-autoconf-3210000.tar.gz \
	&& cd sqlite-autoconf-3210000 \
	&& ./configure \
	&& make \
	&& make install

# Install python
RUN cd /usr/src \
	&& wget https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tar.xz \
	&& tar xf Python-3.7.2.tar.xz \
	&& cd Python-3.7.2 \
	&& ./configure \
	--enable-optimizations \
	--enable-loadable-sqlite-extensions \
	&& make \
	&& make altinstall

RUN ln -s /usr/local/bin/python3.7 /usr/bin/python3.7 \
	&& ln -s /usr/local/bin/pip3.7 /usr/bin/pip3.7
