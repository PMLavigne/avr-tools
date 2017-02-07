#!/bin/bash -e

# Set environment variables we care about
AVR_TOOLS_BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
AVR_TOOLS_SRCDIR="$AVR_TOOLS_BASEDIR/sources";
AVR_TOOLS_PATCHDIR="$AVR_TOOLS_BASEDIR/patches";
AVR_TOOLS_ROOT="$AVR_TOOLS_BASEDIR/toolchain";
AVR_TOOLS_LIB="$AVR_TOOLS_ROOT/lib";
AVR_TOOLS_BIN="$AVR_TOOLS_ROOT/bin";
AVR_TOOLS_INCLUDE="$AVR_TOOLS_ROOT/include";

# Set environment variables other things care about
AVR_GCC="$AVR_TOOLS_BIN/avr-gcc";
AVR_CFLAGS="-I$AVR_TOOLS_ROOT/avr/include";
AVR_LDFLAGS="-L$AVR_TOOLS_ROOT/avr/lib";

# Add AVR Toolchain to the path
PATH="$PATH:$AVR_TOOLS_BIN";

# Export everything we just set
export PATH AVR_TOOLS_BASEDIR AVR_TOOLS_SRCDIR AVR_TOOLS_ROOT AVR_TOOLS_LIB AVR_TOOLS_BIN AVR_TOOLS_INCLUDE \
       AVR_GCC AVR_CFLAGS AVR_LDFLAGS;
