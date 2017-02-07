#!/bin/bash -e

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/environment.sh";

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


if [ ! -f "$AVR_TOOLS_ROOT/.binutils-installed" ]; then
    echo "Making binutils...";
    cd "$BINUTILS_SRC";
    mkdir -p build;
    cd ./build;
    CC=gcc-6 ../configure $CONFIG_GCC --target=$TARGET --enable-plugins --enable-shared --enable-host-shared --enable-lto --enable-install-libiberty;
    make -j8;
    make install;
    cd "$AVR_TOOLS_BASEDIR";
    echo "Done making binutils.";
    touch "$AVR_TOOLS_ROOT/.binutils-installed";
else
    echo "binutils already built.";
fi

if [ ! -f "$AVR_TOOLS_ROOT/.gcc-installed" ]; then
    echo "Making gcc...";
    cd "$GCC_SRC";
    mkdir -p build;
    cd ./build;
    CC=gcc-6 ../configure $CONFIG_GCC --target=$TARGET --with-dwarf2 --with-gnu-as --with-gnu-ld --with-ld="$AVR_TOOLS_BIN/avr-ld" \
        --with-as="$AVR_TOOLS_BIN/avr-as" --disable-threads --disable-libssp --disable-libstdcxx-pch \
        --disable-libgomp --with-gmp=/usr/local/opt/gmp --with-mpfr=/usr/local/opt/mpfr --with-mpc=/usr/local/opt/libmpc;
    make -j8;
    make install;
    cd "$AVR_TOOLS_BASEDIR";
    echo "Done making gcc.";
    touch "$AVR_TOOLS_ROOT/.gcc-installed";
else
    echo "gcc already built.";
fi

if [ ! -f "$AVR_TOOLS_ROOT/.avr-libc-installed" ]; then
    echo "Making avr-libc...";
    cd "$AVR_LIBC_SRC";
    mkdir -p build;
    cd ./build;
    ../configure $CONFIG_COMMON --build="$(./config.guess)" --host="$TARGET" --enable-device-lib;
    make -j8;
    make install;
    cd "$AVR_TOOLS_BASEDIR";
    echo "Done making avr-libc.";
    touch "$AVR_TOOLS_ROOT/.avr-libc-installed";
else
    echo "avr-libc already built.";
fi


if [ ! -f "$AVR_TOOLS_ROOT/.simulavr-installed" ]; then
    echo "Making simulavr...";
    cd "$SIMULAVR_SRC";

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
    AVR_GCC="$AVR_GCC $AVR_CFLAGS $AVR_LDFLAGS" make -j8;
    AVR_GCC="$AVR_GCC $AVR_CFLAGS $AVR_LDFLAGS" make install;
    cd "$AVR_TOOLS_SRCDIR";
    echo "Done making simulavr.";
    touch "$AVR_TOOLS_ROOT/.simulavr-installed";
else
    echo "simulavr already built.";
fi
