#!/bin/bash

set -ex  # Abort on error.

# Patch host numpy to allow cross-compile
# https://github.com/numpy/numpy/issues/28352
pushd "$BUILD_PREFIX"/lib/python3.1?/site-packages
patch -p1 < "$RECIPE_DIR/numpy_host_meson.patch"
popd

mkdir build
cd build

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DENABLE_PYTHON=ON \
    -DBUILD_SHARED_LIBS=ON \
    ${CMAKE_ARGS} \
    "${SRC_DIR}"

make -j"${CPU_COUNT}"
make install

# NOTE: Guard against testing during cross-compilation builds, as the compiled
# binaries will typically fail.
if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
    # NOTE: On osx64, disable tests that fail when building shared libraries. As a
    # kluge we check an env var set by the conda-forge build process to detect this.
    if [[ -z "${OSX_ARCH}" ]]; then
        ctest --output-on-failure -j"${CPU_COUNT}" -E "test_pyncepbufr_write"

        # This test needs to run later
        ctest --output-on-failure -j"${CPU_COUNT}" -R "test_pyncepbufr_write"
    else
        echo "Building on OSX; disabling known failing/flaky tests."
        ctest --output-on-failure -j"${CPU_COUNT}" \
            -E "test_pyncepbufr_write|intest(6|7|8|9|10|12)_*|outtest(1|4|7|9|10)_*|test_debufr"
    fi
fi
