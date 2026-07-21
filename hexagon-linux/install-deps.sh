#!/usr/bin/env sh

# https://www.thundercomm.com/rubik-pi-3/en/docs/rubik-pi-3-user-manual/1.0.0-u/linux-kernel

set -ex

# Install dependencies mentioned in the docs (see link at the top)
sudo apt update
sudo apt install bc bison build-essential clang cpio debhelper \
                 default-jdk-headless dkms dwarfdump dwarves fakeroot \
                 flex gawk gcc git libbabeltrace-dev libcap-dev \
                 libclang-dev libdebuginfod-dev libdw-dev libelf-dev \
                 liblzma-dev libncurses5-dev libnuma-dev libpci-dev \
                 libpfm4-dev libslang2-dev libssl-dev libtraceevent-dev \
                 libudev-dev libunwind-dev llvm make pkg-config \
                 python3-dev systemtap-sdt-dev zip zstd

# Install rustup if it's not installed already
if ! command -v rustup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi

# Install rust with specific version
rustup override set "$(scripts/min-tool-version.sh rustc)"
rustup component add rust-src

# Install bindgen with specific version
cargo install bindgen-cli --version=0.65.1

# debian/rules.d/0-common-vars.mk hardcodes the bindgen binary name as
# bindgen-0.65, but cargo installs it as plain "bindgen"
ln -sf "$HOME/.cargo/bin/bindgen" "$HOME/.cargo/bin/bindgen-0.65"

make LLVM=1 rustavailable
