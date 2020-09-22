#!/bin/bash

set +e -x

echo ==== Versions and misc info ====
gcc --version    | head -1
cmake --version  | head -1
echo Ninja `ninja --version`
{ ninja --help || true ; } 2>&1 | grep "run N jobs in parallel"
ccache --version | head -1
echo
echo ==== ccache configuration ====
ccache --show-config  ||  echo 'Old ccache version does not support --show-config'
echo
echo ==== Environment ====
printenv
echo
echo ==== CMakeOutput.log ====
cat build/CMakeFiles/CMakeOutput.log
echo
echo ==== CMakeError.log ====
cat build/CMakeFiles/CMakeError.log
echo
echo ==== CMakeCache.txt ====
cat build/CMakeCache.txt
