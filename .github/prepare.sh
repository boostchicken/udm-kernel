#!/bin/bash
# Script to prepare the configuration for a UDM(P) kernel.

# Print the help message of this script.
usage() {
	cat << EOF

Usage: $0 [OPTIONS...]

Prepare the configuration for a custom kernel.

Options:
  -V            Specify custom local version for this kernel
  -m            Graphically configure the kernel options
  -s            Use stock configuration
  -h, --help    Show this message and exit
EOF
}

version=
menu=
stock=

while getopts ":hV:ms" arg; do
case $arg in
    V)
        version=$OPTARG
        ;;
    m)
        menu=y
        ;;
    s)
        stock=y
        ;;
    h | *) # Display help.
        usage
        exit 0
        ;;
    esac
done
shift $((OPTIND - 1))

echo "Preparing kernel configuration..."

if [ -n "$stock" ]; then
    scripts/kconfig/merge_config.sh -m .github/config/config.stock.udm
else
    scripts/kconfig/merge_config.sh -m .github/config/config.stock.udm .github/config/config.edge.udm

    # Support local options
    if [ -f .github/config/config.local.udm ]; then
        scripts/kconfig/merge_config.sh -m .config .github/config/config.local.udm
        CONFIG_FILES="$CONFIG_FILES .github/config/config.local.udm"
    fi
fi

# Support version specification
if [ -n "$version" ]; then
    scripts/config --set-str CONFIG_LOCALVERSION "-$version"
fi

# Ensure the cross compilation settings are configured
export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-

echo "Configuring kernel..."
if [ -n "$menu" ]; then
    make menuconfig
else
    make olddefconfig
fi
