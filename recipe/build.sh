#!/bin/bash

set -ex  # Abort on error.

mkdir build
cd build

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DENABLE_PYTHON=ON \
    -DBUILD_SHARED_LIBS=ON \
    "${SRC_DIR}"

make -j"${CPU_COUNT}"
make install

# NOTE: Guard against testing during cross-compilation builds, as the compiled
# binaries will typically fail.
if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
    # NOTE: On osx64, disable tests that fail when building shared libraries. As a
    # kluge we check an env var set by the conda-forge build process to detect this.
    if [[ -z "${OSX_ARCH}" ]]; then
        ctest --output-on-failure -j"${CPU_COUNT}"
    else
        echo "Building on OSX; disabling known failing/flaky tests."
        ctest --output-on-failure -j"${CPU_COUNT}" \
            -E "test_pyncepbufr_write|intest(7|10|12)_*|outtest(1|4|9|10)_*|test_debufr"
    fi
fi