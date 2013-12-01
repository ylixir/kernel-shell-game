#!/bin/bash
# vim: noai:ts=4:sw=4

#   Copyright 2013 Jon Allen (ylixir@gmail.com)
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# builder.sh
# this is the main script for controlling the build environment and such

source configuration
source functions

# figure out what architecture we want for our chroot
# but only if it wasn't manually set in the configuration file
if [ -z "$ROOT_ARCH" ]; then
  get_architecture;
  echo "Selecting $ROOT_ARCH arcitecture for you";
else
  echo "Using $ROOT_ARCH architecture from configuration file";
fi

# decide what to do depending on the first command line parameter
case "$1" in
  clean)
    echo "Cleaning out the deboot, chroot, and kernel directories"
    clean_directories
    exit 0
    ;;
  setup)
    echo "Creating the deboot, chroot, and kernel directories"
    create_directories
    echo "Setting up deboot"
    get_deboot
    echo "Patching deboot"
    patch_deboot
    echo "Creating the chroot build environment"
    deboot_chroot
    ;;
esac
exit 0

cd $BASE_DIR
mkdir -p $ROOT_TARGET
DEBOOTSTRAP_DIR=$BASE_DIR/$DEBOOT_DIR/usr/share/debootstrap
export DEBOOTSTRAP_DIR
$BASE_DIR/$DEBOOT_DIR/usr/sbin/debootstrap --arch=$ROOT_ARCH --include=$REQUIRED_PACKAGES --no-check-gpg $ROOT_SUITE $BASE_DIR/$ROOT_TARGET $ROOT_SOURCE

echo Unmounting proc from chroot
umount $BASE_DIR/$ROOT_TARGET/proc

#stop dpkg from running daemons
echo Disabling dpkg daemons
cat > $BASE_DIR/$ROOT_TARGET/usr/sbin/policy-rc.d <<EOF
#!/bin/sh
exit 101
EOF
chmod a+x $BASE_DIR/$ROOT_TARGET/usr/sbin/policy-rc.d

#divert ischroot
#note that this throws error, my need to be fixed, not sure
echo Diverting ischroot
chroot $BASE_DIR/$ROOT_TARGET dpkg-divert --divert /usr/bin/ischroot.debianutils --rename /usr/bin/ischroot
chroot $BASE_DIR/$ROOT_TARGET /bin/ln -s /bin/true /usr/bin/ischroot
