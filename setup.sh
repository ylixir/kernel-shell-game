#!/bin/bash
# vim: noai:ts=4:sw=4

BASE_DIR=`pwd`
DEBOOT_DEB=debootstrap_1.0.55_all.deb
DEBOOT_TMP=deboot_working
ROOT_DIR=root

if [ 'clean' == "$1" ]; then
  echo "Removing the debian chroot"
  rm -rf $ROOT_DIR
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

# this patch from http://blog.tsunanet.net/2013/01/using-debootstrap-with-grsec.html?m=1
MOUNT_PATCH="--- usr/share/debootstrap/functions.orig	2013-11-26 07:15:53.909242727 -0600
+++ usr/share/debootstrap/functions	2013-11-26 07:17:39.464665969 -0600
@@ -998,12 +998,14 @@
 		umount_on_exit /proc/bus/usb
 		umount_on_exit /proc
 		umount "'"'"\$TARGET/proc"'"'" 2>/dev/null || true
-		in_target mount -t proc proc /proc
+#		in_target mount -t proc proc /proc
+		sudo mount -o bind /proc "'"'"\$TARGET/proc"'"'"
 		if [ -d "'"'"\$TARGET/sys"'"'" ] && \\
 		   grep -q '[[:space:]]sysfs' /proc/filesystems 2>/dev/null; then
 			umount_on_exit /sys
 			umount "'"'"\$TARGET/sys"'"'" 2>/dev/null || true
-			in_target mount -t sysfs sysfs /sys
+#			in_target mount -t sysfs sysfs /sys
+			sudo mount -o bin /sys "'"'"\$TARGET/sys"'"'"
 		fi
 		on_exit clear_mtab
 		;;
"

mkdir -p $DEBOOT_TMP
cd $DEBOOT_TMP
wget -c http://ftp.debian.org/debian/pool/main/d/debootstrap/$DEBOOT_DEB
ar -x $DEBOOT_DEB
tar -xf data.tar.xz
printf '%s' "$MOUNT_PATCH"|patch --ignore-whitespace --verbose usr/share/debootstrap/functions

cd $BASE_DIR
mkdir -p $ROOT_DIR
DEBOOTSTRAP_DIR=$BASE_DIR/$DEBOOT_TMP/usr/share/debootstrap
export DEBOOTSTRAP_DIR
$BASE_DIR/$DEBOOT_TMP/usr/sbin/debootstrap --arch $ARCH --no-check-gpg wheezy $BASE_DIR/$ROOT_DIR http://http.debian.net/debian

echo Unmounting proc from chroot
umount $BASE_DIR/$ROOT_DIR/proc

#stop dpkg from running daemons
echo Disabling dpkg daemons
cat > $BASE_DIR/$ROOT_DIR/usr/sbin/policy-rc.d <<EOF
#!/bin/sh
exit 101
EOF
chmod a+x $BASE_DIR/$ROOT_DIR/usr/sbin/policy-rc.d

#divert ischroot
#note that this throws error, my need to be fixed, not sure
echo Diverting ischroot
chroot $BASE_DIR/$ROOT_DIR dpkg-divert --divert /usr/bin/ischroot.debianutils --rename /usr/bin/ischroot
chroot $BASE_DIR/$ROOT_DIR /bin/ln -s /bin/true /usr/bin/ischroot
