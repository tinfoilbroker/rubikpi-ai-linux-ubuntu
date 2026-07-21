#!/usr/bin/env sh

# Native (on-device, arm64) kernel package build.
# https://www.thundercomm.com/rubik-pi-3/en/docs/rubik-pi-3-user-manual/1.0.0-u/linux-kernel

set -eux

cd "$(dirname "$0")/.."

fakeroot debian/rules clean
fakeroot debian/rules build
fakeroot debian/rules binary
