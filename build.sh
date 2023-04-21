#!/bin/bash
set -ex
source bash-scripts/helpers.sh
run_shfmt_and_shellcheck ./*.sh
docker_setup "jpeg-recompress-appimage"
dockerfile_create
dockerfile_appimage
dockerfile_switch_to_user
cp AppRun "$(dirname "$DOCKERFILE")"
cp jpeg-archive.desktop "$(dirname "$DOCKERFILE")"
cat >>"$DOCKERFILE" <<'EOF'
WORKDIR /work
RUN set -ex \
    && git clone https://github.com/mozilla/mozjpeg.git \
    && mkdir -p build_mozjpeg \
    && cd build_mozjpeg \
    && cmake -G"Unix Makefiles" -DPNG_SUPPORTED=0 -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=/usr/lib ../mozjpeg \
    && make -j install DESTDIR=/work/AppDir
RUN set -ex \
    && git clone https://github.com/sourcejedi/jpeg-archive.git \
    && cd jpeg-archive \
    && git checkout extern \
    && make MOZJPEG_PREFIX=/work/AppDir/usr LIBJPEG=/work/AppDir/usr/lib/libjpeg.a \
    && make install PREFIX=/work/AppDir
COPY jpeg-archive.desktop /work/AppDir/jpeg-archive.desktop
RUN set -ex \
    && rm -rf /work/AppDir/usr/ \
    && rm -f /work/AppDir/bin/jpeg-archive \
    && rm -f /work/AppDir/bin/jpeg-hash \
    && rm -f /work/AppDir/bin/jpeg-compare
RUN set -ex \
    && export LD_LIBRARY_PATH=/work/AppDir/usr/lib/ ; find /work/AppDir/ -type f -executable -exec ldd {} \; | grep "not found" | true \
    && cp /usr/share/icons/Adwaita/scalable/mimetypes/application-x-executable-symbolic.svg /work/AppDir \
    && ./appimagetool-x86_64.AppImage --appimage-extract-and-run AppDir \
    && chmod +x jpeg-recompress-x86_64.AppImage
RUN set -ex \
    && cd /work/AppDir \
    && strace ./AppRun || true
EOF
docker_build_image_and_create_volume
mkdir -p release
if [ $# -eq 0 ]; then
	$DOCKER_RUN_I cp jpeg-recompress-x86_64.AppImage /mnt/release
else
	$DOCKER_RUN_I "$@"
fi
