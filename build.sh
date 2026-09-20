#!/bin/bash

export PROTON_VERSION="Proton11-7"

PROTON_RELEASE="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-${PROTON_VERSION}/GE-${PROTON_VERSION}-x86_64.tar.gz"

# Download required mingw64 dlls
brotli=('brotli-1.2.0-1' 'libbrotlicommon libbrotlidec')
cares=('c-ares-1.34.8-1' 'libcares-2')
curl=('curl-8.20.0-1' 'libcurl-4')
gettext=('gettext-runtime-1.0-1' 'libintl-8 libasprintf-0')
libiconv=('libiconv-1.19-1' 'libiconv-2 libcharset-1')
libidn2=('libidn2-2.3.8-4' 'libidn2-0')
libpsl=('libpsl-0.21.5-3' 'libpsl-5')
libssh2=('libssh2-1.11.1-2' 'libssh2-1')
libunistring=('libunistring-1.4.2-1' 'libunistring-5')
nghttp2=('nghttp2-1.69.0-1' 'libnghttp2-14')
nghttp3=('nghttp3-1.9.0-1' 'libnghttp3-9')
ngtcp2=('ngtcp2-1.22.1-1' 'libngtcp2-16 libngtcp2_crypto_ossl-0 libngtcp2_crypto_gnutls-8')
openssl=('openssl-3.6.2-2' 'libcrypto-3-x64 libssl-3-x64')
zlib=('zlib-1.3.2-2' 'zlib1')
zstd=('zstd-1.5.7-2' 'libzstd')

packages=(brotli cares curl gettext libiconv libidn2 libpsl libssh2 libunistring nghttp2 nghttp3 ngtcp2 openssl zlib zstd)

mkdir -p build
cd build
mkdir -p extra
cd extra

declare -n package
for package in ${packages[@]}; do
    name=package[0]
    if [ name == "cares" ]; then
        name="c-ares"
    fi
    echo "Downloading ${package[0]}..."
    curl "https://repo.msys2.org/mingw/mingw64/mingw-w64-x86_64-${package[0]}-any.pkg.tar.zst" -o - | tar --zstd -x $(echo ${package[1]} | xargs printf -- 'mingw64/bin/%s.dll ')--transform "s/mingw64\/bin\///"
done

# Copy libngtcp2_crypto_ossl-0.dll to libngtcp2_crypto_ossl.dll
cp libngtcp2_crypto_ossl-0.dll libngtcp2_crypto_ossl.dll

# Rename libcurl-4.dll to XCurl.dll
mv libcurl-4.dll XCurl.dll

cd ..

# Configure WineGDK.
../WineGDK/configure --enable-win64

# Build WineGDK.
make -j$(nproc)

cd ..

# Download and extract Proton GE.
curl -L $PROTON_RELEASE -o proton.tar.gz
mkdir -p "GDK-${PROTON_VERSION}"
tar -xf proton.tar.gz -C "GDK-${PROTON_VERSION}" --strip-components=1
rm -f proton.tar.gz

# Patch Proton python script to include extra dlls.
./patch_proton.sh

# Copy wine extra dlls to proton directory.
cp -r build/extra/* "GDK-${PROTON_VERSION}/files/lib/wine/x86_64-windows"

# Copy select compiled WineGDK dlls to proton directory.
declare -A dlls=(
    [xgameruntime]=xgameruntime
    [windows.ui.core.textinput]=windows.ui.core.textinput
    [windows.devices.enumeration]=windows.devices.enumeration
    [windows.appruntime.bootstrap]=Microsoft.WindowsAppRuntime.Bootstrap
    [wintypes]=wintypes
    [twinapi.appcore]=twinapi.appcore
)

for src in "${!dlls[@]}"; do
    dst=${dlls[$src]}
    cp -f "build/dlls/${src}/x86_64-windows/${dst}.dll" \
       "GDK-${PROTON_VERSION}/files/lib/wine/x86_64-windows/${dst}.dll"
done

# Repackage Proton GE with the patched files.
mkdir -p proton
mv "GDK-${PROTON_VERSION}" "proton/GDK-${PROTON_VERSION}"
tar -czf GDK-${PROTON_VERSION}-x86_64.tar.gz -C "proton" .
