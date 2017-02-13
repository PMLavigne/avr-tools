#!/bin/bash -e

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/environment.sh";

if ! isStateEnabled "components-downloaded" > /dev/null || ! isStateEnabled "components-patched" > /dev/null; then
    "$AVR_TOOLS_BASEDIR"/get-sources.sh;
fi

if isStateEnabled "components-installed"; then
    echo "AVR toolchain already installed at $AVR_TOOLS_ROOT";
    exit;
fi

echo "Installing AVR toolchain to: $AVR_TOOLS_ROOT";

mkdir -p "$AVR_TOOLS_ROOT" "$AVR_TOOLS_LIB" "$AVR_TOOLS_BIN" "$AVR_TOOLS_INCLUDE";

BINUTILS_SRC="$AVR_TOOLS_SRCDIR/binutils";
GCC_SRC="$AVR_TOOLS_SRCDIR/gcc";
AVR_LIBC_SRC="$AVR_TOOLS_SRCDIR/avr-libc";
SWIG_SRC="$AVR_TOOLS_SRCDIR/swig";
SIMULAVR_SRC="$AVR_TOOLS_SRCDIR/simulavr";

BUILD_FOR="$($BINUTILS_SRC/config.guess)";
TARGET="avr";
CONFIG_COMMON="--prefix=$AVR_TOOLS_ROOT --disable-dependency-tracking";
CONFIG_GCC="$CONFIG_COMMON --with-system-zlib --disable-nls --disable-werror --disable-debug --enable-languages=c,c++";

echo "Building for platform $BUILD_FOR targeting $TARGET";

BINUTILS_LIBS_DIR="$AVR_TOOLS_ROOT/$BUILD_FOR/$TARGET";

#if [ ! -d "$BINUTILS_LIBS_DIR" ]; then
#    mkdir -p "$AVR_TOOLS_ROOT/$BUILD_FOR" "$AVR_TOOLS_ROOT/$TARGET";
#    ln -s "$AVR_TOOLS_ROOT/$TARGET" "$BINUTILS_LIBS_DIR";
#fi


function configure-binutils() {
   mkdir -p build;
   cd ./build;
   ../configure $CONFIG_GCC --target=$TARGET --enable-plugins --enable-shared --enable-host-shared --enable-lto --enable-install-libiberty;
}

function make-binutils() {
    make -j8;
}

function make-install-binutils() {
    make install;
}

function configure-gcc() {
    mkdir -p build;
    cd ./build;
    ../configure $CONFIG_GCC --target=$TARGET --with-dwarf2 --with-gnu-as --with-gnu-ld --with-ld="$AVR_TOOLS_BIN/avr-ld" \
                             --with-as="$AVR_TOOLS_BIN/avr-as" --disable-threads --disable-libssp --disable-libstdcxx-pch \
                             --disable-libgomp --with-gmp=/usr/local/opt/gmp --with-mpfr=/usr/local/opt/mpfr --enable-lto \
                             --with-mpc=/usr/local/opt/libmpc;
}

function make-gcc() {
    make -j8;
}

function make-install-gcc() {
    make install;
}

function configure-avr-libc() {
    mkdir -p build;
    cd ./build;
    CC= ../configure $CONFIG_COMMON --build="$(./config.guess)" --host="$TARGET" --enable-device-lib;
}

function make-avr-libc() {
    CC= make -j8;
}

function make-install-avr-libc() {
    CC= make install;
}

function configure-simulavr() {
    # Bootstrap is required for simulavr
    ./bootstrap

    # NOTE: This directory should be created automatically but isn't!
    mkdir -p src/.deps;

    # Building the examples causes errors due to the libs not being pulled in properly
    AVR_GCC="$AVR_GCC $AVR_CFLAGS $AVR_LDFLAGS" \
    ./configure $CONFIG_COMMON \
        --with-bfd="$BINUTILS_LIBS_DIR" \
        --with-libiberty="$AVR_TOOLS_ROOT" \
        --with-tclconfig="/usr/local/opt/tcl-tk/lib" \
        --enable-tcl \
        --enable-verilog \
        --enable-python;
}

function make-simulavr() {
    AVR_GCC="$AVR_GCC $AVR_CFLAGS $AVR_LDFLAGS" make -j8;

}

function make-install-simulavr() {
    AVR_GCC="$AVR_GCC $AVR_CFLAGS $AVR_LDFLAGS" make install;
}

function configure-gdb() {
    mkdir -p build;
    cd build;
    ../configure $CONFIG_GCC --target=$TARGET --with-dwarf2 --with-gnu-as --with-gnu-ld --with-ld="$AVR_TOOLS_BIN/avr-ld" \
                             --with-as="$AVR_TOOLS_BIN/avr-as" --with-gmp=/usr/local/opt/gmp --with-mpfr=/usr/local/opt/mpfr \
                             --with-mpc=/usr/local/opt/libmpc --with-build-time-tools="$AVR_TOOLS_BIN";
}

function make-gdb() {
    make -j8;
}

function make-install-gdb() {
    make install;
}

function installComponent() {
    if isStateEnabled "$1-installed"; then
        echo "$1 is already installed.";
        return 0;
    fi;
    echo "Configuring $1...";
    cd "$AVR_TOOLS_SRCDIR/$1";
    configure-$1;
    echo "Building $1...";
    make-$1;
    echo "Installing $1...";
    make-install-$1;
    echo "$1 installed successfully.";
    setStateVal "$1-installed" "true";
    cd "$AVR_TOOLS_BASEDIR";
}

for component in 'binutils' 'gcc' 'avr-libc' 'simulavr' 'gdb'; do
    installComponent "$component";
done;

echo "Installation complete.";
setStateVal "components-installed" "true";
