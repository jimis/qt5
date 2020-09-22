#!/bin/bash

set -eux -o pipefail

# Install with DESTDIR set, means that the whole "prefix" hierarchy
# that we've set in configure will be formulated under DESTDIR.
# The reason is to avoid mixing with other stuff installed under prefix.
DESTDIR=dest_dir  cmake --install build --strip

# double escaping backslash because of bash double quotes and sed
tempdir_without_drive="`echo "$RUNNER_TEMP" | sed 's/^[A-Z]:\\\\//'`"

# Separate stripping step, as `--strip` above is broken on CMake on Windows
# because of DESTDIR - https://gitlab.kitware.com/cmake/cmake/-/issues/16859
if [ "$RUNNER_OS" = Windows ]
then
    find dest_dir -type f  \
        -iregex '.*\.\(exe\|dll\|a\)$'  \
        -print  -exec  strip --strip-unneeded '{}' ';'
fi

# Create tarball
tar -cf - -C "dest_dir/$tempdir_without_drive"  install_dir/  \
    |  zstd -c > install_dir.tar.zst
