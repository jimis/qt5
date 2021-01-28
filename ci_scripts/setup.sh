#!/bin/bash

set -eux -o pipefail

# $RUNNER_OS is either Linux, macOS, or Windows.
# $ImageOS is more detailed.

case "$ImageOS" in
    ubuntu20)
        DEPS="libgl-dev libglu-dev libxcb*-dev libx11-xcb-dev libxkbcommon-x11-dev libpcre2-dev libz-dev libfreetype6-dev libpng-dev libjpeg-dev libsqlite3-dev libharfbuzz-dev libb2-dev libdouble-conversion-dev libmd4c-dev"
        TOOLS="ninja-build ccache"
        INSTALL_CMD="sudo apt-get -y install"
        CONFIGURE_FLAGS="-xcb -system-sqlite -system-pcre -system-zlib -system-freetype -system-libpng -system-libjpeg -system-harfbuzz -system-libb2 -system-doubleconversion -system-libmd4c"
        ;;
    ubuntu18)
        DEPS="libgl-dev libglu-dev libxcb*-dev libx11-xcb-dev libxkbcommon-x11-dev libpcre2-dev libz-dev libfreetype6-dev libpng-dev libjpeg-dev libsqlite3-dev libharfbuzz-dev libb2-dev libdouble-conversion-dev"
        TOOLS="ninja-build ccache"
        INSTALL_CMD="sudo apt-get -y install"
        CONFIGURE_FLAGS="-xcb -system-sqlite -system-pcre -system-zlib -system-freetype -system-libpng -system-libjpeg -system-harfbuzz -system-libb2 -system-doubleconversion"
        ;;
    macos1015)
        DEPS="jpeg sqlite libpng pcre2 harfbuzz freetype libb2 double-conversion"
        TOOLS="ninja ccache pkg-config"
        INSTALL_CMD="brew install"
        CONFIGURE_FLAGS="-pkg-config -system-sqlite -system-pcre -system-zlib -system-freetype -system-libpng -system-libjpeg -system-harfbuzz -system-libb2 -system-doubleconversion"
        ;;
    win19)
        DEPS=""
        TOOLS="ninja"
        INSTALL_CMD="choco install"
        INSTALL_CMD_POSTFIX="--yes --no-progress"
        CONFIGURE_FLAGS="-qt-sqlite -qt-pcre -qt-zlib -qt-freetype -qt-libpng -qt-libjpeg -qt-harfbuzz -no-feature-sql-psql -no-feature-sql-mysql -no-feature-sql-odbc"
        BAT_EXTENSION=".bat"
        ;;
esac


case "$RUNNER_OS" in
    Linux)
        sudo apt-get update
        ;;
    macOS)
        export HOMEBREW_NO_INSTALL_CLEANUP=1
        ;;
    Windows)
        # Header pthread.h from postgres is included and creates issues.
        # Also library zlib.lib is linked instead of the system one.
        rm -rf "C:/Program Files/PostgreSQL/"
        choco install ccache --version 3.7.12 --yes --no-progress --not-silent --verbose --debug
    ;;
esac


# Install build dependencies
[ -z "$DEPS" ]  \
    || $INSTALL_CMD  $DEPS  ${INSTALL_CMD_POSTFIX:-}

# Install tools
$INSTALL_CMD  $TOOLS  ${INSTALL_CMD_POSTFIX:-}

# Configure ccache
ccache --set-config sloppiness=file_macro,time_macros
ccache --set-config cache_dir="$RUNNER_TEMP"/ccache
ccache --set-config compression=true
ccache --set-config max_size=1G

# Make build directory
mkdir build


# EXPORT VARIABLES

# Set a variable for repo name without owner prefix; for example "qtbase"
echo GITHUB_REPO_NAME=$(echo "$GITHUB_REPOSITORY" | sed -e "s,[^/]*/,," -e "s/:refs//")  >> $GITHUB_ENV
echo CONFIGURE_FLAGS="$CONFIGURE_FLAGS"  >> $GITHUB_ENV
echo BAT_EXTENSION="${BAT_EXTENSION:-}"  >> $GITHUB_ENV
