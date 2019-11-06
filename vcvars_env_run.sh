# MIT License
#
# Copyright (c) 2019 Romain Pokrzywka
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#!/usr/bin/env bash

if [[ ! $(uname -r) =~ Microsoft ]]; then
    echo "This script only works in a WSL environment!"
    exit 1
fi

# This will find all Visual Studio installs and return the latest version
# Note that we're not explicitly checking for the VC toolchain
# The vswhere.exe tool handles custom VS installation paths, but for the tool itself
# which is part of the VS installer, we assume it is in the standard install path
VSWHERE_PATH="/mnt/c/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
VS_INSTALL_DIR=$("${VSWHERE_PATH}" -latest -property installationPath)

if [[ -z "${VS_INSTALL_DIR}" ]]; then
    echo "No valid Visual Studio install found! Can't proceed."
    exit 2
fi

VCVARS_BAT="${VS_INSTALL_DIR}\VC\Auxiliary\Build\vcvars64.bat"

# the per-argument quoting is necessary to correctly parse quoted arguments with spaces
cmd.exe /V /C @ "${VCVARS_BAT}" "&&" "$@"

# propagate the executed command's return code back to the caller
exit $?
