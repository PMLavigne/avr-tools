#!/bin/bash

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/environment.sh";

BINUTILS_VERSION="2.27";
BINUTILS_URL="http://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.bz2";

GCC_VERSION="6.3.0";
GCC_URL="http://mirrors.concertpass.com/gcc/releases/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.bz2";

AVR_LIBC_VERSION="2.0.0";
AVR_LIBC_URL="http://download.savannah.gnu.org/releases/avr-libc/avr-libc-$AVR_LIBC_VERSION.tar.bz2";


function downloadComponent() {
    if [ -d "$AVR_TOOLS_SRCDIR/$1" ]; then
        echo "Already have $1, skipping";
    else
        echo "Downloading $1 v$2";
        mkdir -p "$AVR_TOOLS_SRCDIR/$1";
        curl "$3" | tar xj -C "$AVR_TOOLS_SRCDIR/$1" --strip-components 1;
        echo "Done downloading $1 v$2";
    fi
}

function patchComponent() {
    for patch in "$AVR_TOOLS_PATCHDIR/$1/*.patch"; do
        echo "Applying $patch to $1";
        cd "$AVR_TOOLS_SRCDIR/$1";
        patch -p1 < "$patch";
        cd "$AVR_TOOLS_BASEDIR";
    done;

    for patch in "$AVR_TOOLS_PATCHDIR/$1/*.gitpatch"; do
        echo "Applying git patch $patch to $1";
        cd "$AVR_TOOLS_SRCDIR/$1";
        git apply "$patch";
        cd "$AVR_TOOLS_BASEDIR";
    done;
}

echo "Downloading AVR Toolchain sources to $AVR_TOOLS_SRCDIR...";

downloadComponent "binutils" "$BINUTILS_VERSION" "$BINUTILS_URL";
downloadComponent "gcc" "$GCC_VERSION" "$GCC_URL";
downloadComponent "avr-libc" "$AVR_LIBC_VERSION" "$AVR_LIBC_URL";

echo "Updating git submodules..."
git submodule init && git submodule update;

echo "Applying patches..."

for component in 'binutils' 'gcc' 'avr-libc' 'simulavr'; do
    patchComponent "$component";
done

echo "Done.";
