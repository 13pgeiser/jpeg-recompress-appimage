FROM debian:buster

# Install base deps
RUN set -ex \
    && apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
	git \
	ca-certificates \
	build-essential \
	cmake \
	autoconf \
	automake \
	libtool \
	pkg-config \
	wget \
	yasm \
	libfuse2 \
	strace \
	adwaita-icon-theme \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

RUN set -ex \
    && git clone https://github.com/mozilla/mozjpeg.git \
    && mkdir -p build_mozjpeg \
    && cd build_mozjpeg \
    && cmake -G"Unix Makefiles" -DPNG_SUPPORTED=0 -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=/usr/lib ../mozjpeg \
    && make -j install DESTDIR=/AppDir

RUN set -ex \
    && git clone https://github.com/danielgtaylor/jpeg-archive.git \
    && cd jpeg-archive \
    && make -j MOZJPEG_PREFIX=/AppDir/usr LIBJPEG=/AppDir/usr/lib/libjpeg.a \
    && make install PREFIX=/AppDir

RUN set -ex \
    && wget https://github.com/AppImage/AppImageKit/releases/download/12/appimagetool-x86_64.AppImage \
    && chmod +x appimagetool-x86_64.AppImage

COPY AppRun AppDir/AppRun

COPY jpeg-archive.desktop AppDir/jpeg-archive.desktop

RUN set -ex \
    && rm -rf /AppDir/usr/ \
    && rm -f /AppDir/bin/jpeg-archive \
    && rm -f /AppDir/bin/jpeg-hash \
    && rm -f /AppDir/bin/jpeg-compare \
    && find /AppDir \
    && chmod a+x AppDir/AppRun

RUN set -ex \
    && export LD_LIBRARY_PATH=/AppDir/usr/lib/ ; find /AppDir/ -type f -executable -exec ldd {} \; | grep "not found" | true \
    && cp /usr/share/icons/Adwaita/scalable/mimetypes/application-x-executable-symbolic.svg /AppDir \
    && ./appimagetool-x86_64.AppImage --appimage-extract-and-run AppDir

RUN set -ex \
    && cd /AppDir \
    && strace ./AppRun || true

