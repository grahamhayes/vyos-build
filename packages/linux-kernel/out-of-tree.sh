#!/bin/bash
set -eux

SENSORS_REPO_URL=${SENSORS_REPO_URL:-https://gitlab.com/traversetech/ls1088firmware/traverse-sensors.git}

BASEDIR=$(pwd)

SANITIZED_CODENAME=$(echo "${CHANGELOG_DIST}" | sed "s/_/-/g")

KERNEL_HEADER_DEB=linux-headers-5.10.110-arm64-vyos_5.10.110-1_arm64.deb
sudo dpkg -i linux-headers-5.10.110-arm64-vyos_5.10.110-1_arm64.deb
KERNEL_VERSION=$(dpkg-deb --info "${KERNEL_HEADER_DEB}" | grep "Package: linux-headers" | sed "s/ Package: linux-headers-//g")
# Traverse sensors
mkdir -p external
#git clone --branch add_emc2301 "${SENSORS_REPO_URL}" external/traverse-sensors
. "external/traverse-sensors/dkms.conf"
# Append git commit version or reference to DKMS package version
PATCHSET_VERSION=$(git --git-dir "external/traverse-sensors/.git" rev-parse --short HEAD)
export APPENDED_VERSION="${PACKAGE_VERSION}+${PATCHSET_VERSION}"
echo "Setting dkms version to ${APPENDED_VERSION}"
sed -i "s/PACKAGE_VERSION=\".*\"/PACKAGE_VERSION=\"${APPENDED_VERSION}\"/g" "external/traverse-sensors/dkms.conf"
. "external/traverse-sensors/dkms.conf"
sudo cp -r external/traverse-sensors "/usr/src/traverse-sensors-${PACKAGE_VERSION}"
sudo rm -rf "/usr/src/traverse-sensors-${PACKAGE_VERSION}/.git"
sudo dkms build "traverse-sensors/${PACKAGE_VERSION}" -k "${KERNEL_VERSION}"
sudo dkms mkdsc "traverse-sensors/${PACKAGE_VERSION}" -k "${KERNEL_VERSION}"
sudo dkms mkbmdeb "traverse-sensors/${PACKAGE_VERSION}" -k "${KERNEL_VERSION}"

echo "DKMS binaries: "
find "/var/lib/dkms/traverse-sensors/${PACKAGE_VERSION}/bmdeb"

cp -r /var/lib/dkms/traverse-sensors/${PACKAGE_VERSION}/bmdeb/* .
cp -r /var/lib/dkms/traverse-sensors/${PACKAGE_VERSION}/dsc/* .
