#!/bin/bash -e

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/environment.sh";

BINUTILS_VERSION="2.27";
BINUTILS_URL="http://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.bz2";

GCC_VERSION="6.3.0";
GCC_URL="http://mirrors.concertpass.com/gcc/releases/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.bz2";

AVR_LIBC_VERSION="2.0.0";
AVR_LIBC_URL="http://download.savannah.gnu.org/releases/avr-libc/avr-libc-$AVR_LIBC_VERSION.tar.bz2";


function downloadComponent() {
    if isStateEnabled "$1-downloaded" > /dev/null; then
        echo "Already have $1, skipping";
        return 0;
    fi

    echo "Downloading $1 v$2 from $3";
    mkdir -p "$AVR_TOOLS_SRCDIR/$1";
    $DOWNLOAD_UTIL "$3" | tar xj -C "$AVR_TOOLS_SRCDIR/$1" --strip-components 1;
    echo "Done downloading $1 v$2";
    setStateVal "$1-downloaded" "true";
}

function patchComponent() {
    if isStateEnabled "$1-patched" > /dev/null; then
        echo "$1 has already been patched, skipping";
        return 0;
    fi

    if compgen -G "$AVR_TOOLS_PATCHDIR/$1/*.patch" > /dev/null; then
        for patch in "$AVR_TOOLS_PATCHDIR/$1/"*.patch; do
            echo "Applying $patch to $1";
            cd "$AVR_TOOLS_SRCDIR/$1";
            patch -p1 < "$patch";
            cd "$AVR_TOOLS_BASEDIR";
        done;
    fi

    if compgen -G "$AVR_TOOLS_PATCHDIR/$1/*.gitpatch" > /dev/null; then
        for patch in "$AVR_TOOLS_PATCHDIR/$1/"*.gitpatch; do
            echo "Applying git patch $patch to $1";
            cd "$AVR_TOOLS_SRCDIR/$1";
            git apply "$patch";
            cd "$AVR_TOOLS_BASEDIR";
        done;
    fi

    setStateVal "$1-patched" "true";
}

if isStateEnabled "components-downloaded" > /dev/null; then
    echo "AVR Toolchain sources already downloaded.";
else
    echo "Downloading AVR Toolchain sources to $AVR_TOOLS_SRCDIR...";

    downloadComponent "binutils" "$BINUTILS_VERSION" "$BINUTILS_URL";
    downloadComponent "gcc" "$GCC_VERSION" "$GCC_URL";
    downloadComponent "avr-libc" "$AVR_LIBC_VERSION" "$AVR_LIBC_URL";

    echo "Updating git submodules..."
    git submodule init && git submodule update;

    echo "Done downloading sources.";
    setStateVal "components-downloaded" "true";
fi

if isStateEnabled "components-patched" > /dev/null; then
    echo "AVR Toolchain sources already patched.";
else
    echo "Applying patches..."

    for component in 'binutils' 'gcc' 'avr-libc' 'simulavr'; do
        patchComponent "$component";
    done

    echo "Done applying patches.";
    setStateVal "components-patched" "true";
fi
