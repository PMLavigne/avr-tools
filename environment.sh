#!/bin/bash -e

# Set environment variables we care about
AVR_TOOLS_BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
AVR_TOOLS_STATEFILE="$AVR_TOOLS_BASEDIR/.avr-tools-state";
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

# Find some common utilities
# Find sed, use gsed if possible
if which gsed > /dev/null; then
    SED="$(which gsed)";
else
    SED="$(which sed)";
fi

# make
MAKE="$(which make)";

# git
GIT="$(which git)";

# grep
GREP="$(which grep)";

# Use gcc-6 if we can, otherwise use whatever gcc is installed
if which gcc-6 > /dev/null; then
    CC="$(which gcc-6)";
else
    CC="$(which gcc)";
fi

if which wget > /dev/null; then
    DOWNLOAD_UTIL="$(which wget) -O-";
elif which curl > /dev/null; then
    DOWNLOAD_UTIL="$(which curl) -L";
else
    echo "ERROR: You must have either curl or wget installed to continue.";
    exit 1;
fi

# Add AVR Toolchain to the path
PATH="$PATH:$AVR_TOOLS_BIN";

# Export important things we just set
export PATH AVR_TOOLS_BASEDIR AVR_TOOLS_SRCDIR AVR_TOOLS_ROOT AVR_TOOLS_LIB AVR_TOOLS_BIN AVR_TOOLS_INCLUDE \
       AVR_GCC AVR_CFLAGS AVR_LDFLAGS SED MAKE GIT GREP CC;

# Common functions

# Get a value from the state file
function getStateVal() {
    if [ ! -f "$AVR_TOOLS_STATEFILE" ]; then
        touch "$AVR_TOOLS_STATEFILE";
    fi;

    # Escape the key
    local KEY="$(echo -n "$1" | "$SED" -e 's/[]\/$*.^|[]/\\&/g')";

    if [ -z "$KEY" ]; then
        >&2 echo "ERROR: Can't call getStateVal, key \"$1\" invalid";
        return 1;
    fi;

    local VAL="$("$SED" -rn "s/^$KEY[[:space:]]*=[[:space:]]*(.*)$/\1/pg" "$AVR_TOOLS_STATEFILE")";
    if [ -z "$VAL" ]; then
        return 2;
    fi;
    echo -n "$VAL";
    return 0;
}

function isStateEnabled() {
    local KEY="$1";
    local DEFAULT="$2";
    if [ -z "$DEFAULT" ]; then
        local DEFAULT="false";
    fi;

    local VALUE="$(getStateVal "$KEY")";
    case "$VALUE" in
        true)
            return 0;
            ;;
        false)
            return 1;
            ;;
        *)
            if [ "$DEFAULT" = "true" ]; then
                return 0;
            else
                return 1;
            fi
            ;;
    esac
}

function setStateVal() {
    if [ ! -f "$AVR_TOOLS_STATEFILE" ]; then
        touch "$AVR_TOOLS_STATEFILE";
    fi;


    if getStateVal "$1" > /dev/null; then
        local KEY="$(echo -n "$1" | "$SED" -e 's/[]\/$*.^|[]/\\&/g')";
        if [ -z "$KEY" ]; then
            >&2 echo "ERROR: Can't call setStateVal, key \"$1\" invalid";
            return 1;
        fi
        local VAL="$(echo -n "$2" | "$SED" -e 's/[\/&]/\\&/g')";
        "$SED" -i -r "s/^($KEY[[:space:]]*=[[:space:]]*).*$/\1$VAL/g" "$AVR_TOOLS_STATEFILE";
        return $?;
    else
        echo "$1 = $2" >> "$AVR_TOOLS_STATEFILE";
        return 0;
    fi
}
