#!/bin/bash
# vim: noai:ts=4:sw=4

# this is the main script for controlling the build environment and such
source configuration

if [ 'clean' == "$1" ]; then
  echo "Removing the debian chroot"
  rm -rf $ROOT_TARGET
  rm -rf $DEBOOT_TMP
  exit 0;
fi

MACHINE_TYPE=`uname -m`
case "$MACHINE_TYPE" in
  i?86)
    echo "Selecting i386 architecture"
    ARCH=i386
    ;;
  x86_64)
    echo "Selecting amd64 architecture"
    ARCH=amd64
    ;;
  *)
    echo "Your machine is not supported by this script"
    exit 1
    ;;
esac

mkdir -p $DEBOOT_TMP
cd $DEBOOT_TMP
wget -c $DEBOOT_SRC/$DEBOOT_DEB
ar -x $DEBOOT_DEB
tar -xf data.tar.xz
printf '%s' "$MOUNT_PATCH"|patch --ignore-whitespace --verbose usr/share/debootstrap/functions

cd $BASE_DIR
mkdir -p $ROOT_TARGET
DEBOOTSTRAP_DIR=$BASE_DIR/$DEBOOT_TMP/usr/share/debootstrap
export DEBOOTSTRAP_DIR
$BASE_DIR/$DEBOOT_TMP/usr/sbin/debootstrap --arch=$ARCH --include=$REQUIRED_PACKAGES --no-check-gpg $ROOT_SUITE $BASE_DIR/$ROOT_TARGET $ROOT_SOURCE

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
