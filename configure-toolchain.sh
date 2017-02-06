#!/bin/bash -e


BASE_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
SOURCES_ROOT="$BASE_ROOT/sources";
TOOLCHAIN_ROOT="$BASE_ROOT/toolchain";
TOOLCHAIN_LIB="$TOOLCHAIN_ROOT/lib";
TOOLCHAIN_BIN="$TOOLCHAIN_ROOT/bin";
TOOLCHAIN_INCLUDE="$TOOLCHAIN_ROOT/include";

mkdir -p "$TOOLCHAIN_ROOT" "$TOOLCHAIN_LIB" "$TOOLCHAIN_BIN" "$TOOLCHAIN_INCLUDE";

PATH="$PATH:$TOOLCHAIN_BIN";
export PATH;

echo "Installing AVR toolchain to: $TOOLCHAIN_ROOT";

BINUTILS_SRC="$SOURCES_ROOT/binutils";
GCC_SRC="$SOURCES_ROOT/gcc";
AVR_LIBC_SRC="$SOURCES_ROOT/avr-libc";
SWIG_SRC="$SOURCES_ROOT/swig";
SIMULAVR_SRC="$SOURCES_ROOT/simulavr";

BUILD_FOR="$($BINUTILS_SRC/config.guess)";
TARGET="avr";
CONFIG_COMMON="--prefix=$TOOLCHAIN_ROOT --disable-dependency-tracking";
CONFIG_GCC="$CONFIG_COMMON --with-system-zlib --disable-nls --disable-werror --disable-debug --enable-languages=c,c++";

echo "Building for platform $BUILD_FOR targeting $TARGET";

BINUTILS_LIBS_DIR="$TOOLCHAIN_ROOT/$BUILD_FOR/$TARGET";

#if [ ! -d "$BINUTILS_LIBS_DIR" ]; then
#    mkdir -p "$TOOLCHAIN_ROOT/$BUILD_FOR" "$TOOLCHAIN_ROOT/$TARGET";
#    ln -s "$TOOLCHAIN_ROOT/$TARGET" "$BINUTILS_LIBS_DIR";
#fi


if [ ! -f "$TOOLCHAIN_ROOT/.binutils-installed" ]; then
    echo "Making binutils...";
    cd "$BINUTILS_SRC";
    mkdir -p build;
    cd ./build;
    CC=gcc-6 ../configure $CONFIG_GCC --target=$TARGET --enable-plugins --enable-shared --enable-host-shared --enable-lto --enable-install-libiberty;
    make -j8;
    make install;
    cd "$BASE_ROOT";
    echo "Done making binutils.";
    touch "$TOOLCHAIN_ROOT/.binutils-installed";
else
    echo "binutils already built.";
fi

if [ ! -f "$TOOLCHAIN_ROOT/.gcc-installed" ]; then
    echo "Making gcc...";
    cd "$GCC_SRC";
    mkdir -p build;
    cd ./build;
    CC=gcc-6 ../configure $CONFIG_GCC --target=$TARGET --with-dwarf2 --with-gnu-as --with-gnu-ld --with-ld="$TOOLCHAIN_BIN/avr-ld" \
        --with-as="$TOOLCHAIN_BIN/avr-as" --disable-threads --disable-libssp --disable-libstdcxx-pch \
        --disable-libgomp --with-gmp=/usr/local/opt/gmp --with-mpfr=/usr/local/opt/mpfr --with-mpc=/usr/local/opt/libmpc;
    make -j8;
    make install;
    cd "$BASE_ROOT";
    echo "Done making gcc.";
    touch "$TOOLCHAIN_ROOT/.gcc-installed";
else
    echo "gcc already built.";
fi

if [ ! -f "$TOOLCHAIN_ROOT/.avr-libc-installed" ]; then
    echo "Making avr-libc...";
    cd "$AVR_LIBC_SRC";
    mkdir -p build;
    cd ./build;
    ../configure $CONFIG_COMMON --build="$(./config.guess)" --host="$TARGET" --enable-device-lib;
    make -j8;
    make install;
    cd "$BASE_ROOT";
    echo "Done making avr-libc.";
    touch "$TOOLCHAIN_ROOT/.avr-libc-installed";
else
    echo "avr-libc already built.";
fi


if [ ! -f "$TOOLCHAIN_ROOT/.simulavr-installed" ]; then
    echo "Making simulavr...";
    cd "$SIMULAVR_SRC";

    # Bootstrap is required for simulavr
    ./bootstrap

    # NOTE: This directory should be created automatically but isn't!
    mkdir -p src/.deps;

    # Building the examples errors due to these not being pulled in properly
    export AVR_GCC="$TOOLCHAIN_BIN/avr-gcc -I$TOOLCHAIN_ROOT/avr/include -L$TOOLCHAIN_ROOT/avr/lib";
    ./configure $CONFIG_COMMON \
        --with-bfd="$BINUTILS_LIBS_DIR" \
        --with-libiberty="$TOOLCHAIN_ROOT" \
        --with-tclconfig="/usr/local/opt/tcl-tk/lib" \
        --enable-tcl \
        --enable-verilog \
        --enable-python;
    make -j8;
    make install;
    cd "$SOURCES_ROOT";
    echo "Done making simulavr.";
    touch "$TOOLCHAIN_ROOT/.simulavr-installed";
else
    echo "simulavr already built.";
fi
