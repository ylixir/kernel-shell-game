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
  mount)
    echo "Mounting chroot filesystems"
    do_mount
    ;;
  unmount)
    echo "Un mounting chroot filesystems"
    do_unmount
    ;;
  setup)
    echo "Setting up PATH"
    set_path
    echo "Creating the deboot, chroot, and kernel directories"
    create_directories
    echo "Setting up deboot"
    get_deboot
    echo "Bootstrapping stage one"
    deboot_stage_one
    echo "Setting up mountpoints"
    do_mount
    echo "Bootstrapping stage two"
    deboot_stage_two
    echo "Doing post install setup"
    deboot_setup
#somewhere along the line, deboot seems to be unmounting stuff
    echo "Remounting file systems"
    do_unmount
    do_mount
    echo "Upgrading the chroot system"
    upgrade_chroot
    echo "Installing build tools"
    install_build_tools
    echo "Undoing mountpoints"
    do_unmount
    echo "Restoring PATH"
    reset_path
    ;;
  update)
    echo "Upgrading the chroot system"
    upgrade_chroot
    ;;
  kernel)
    case "$2" in
      get)
        echo "Cloning the kernel's source"
        kernel_get
        ;;
      build)
        echo "Building the kernel"
        kernel_build
        ;;
      boot)
        echo "Booting the kernel"
        kernel_boot
        ;;
    esac
    ;;
esac
exit 0

