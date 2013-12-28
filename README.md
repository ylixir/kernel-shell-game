This is a set of scripts to automate the building and testing of a Linux kernel for the 2012 Wi-Fi Nexus 7, also known as grouper. Currently it will create a build environment, download and build the kernel sources, and boot said kernel on the Nexus. Ideally these scripts will work on any linux system, although so far it's only compatible with x86 and x86_64. It requires git, fastboot, and abootimg to be installed on your system.

Many commands require superuser, this is mostly because of the chroot environment it creates to build the kernel in.

Configuration can be accomplished by editing the `configuration` file. Syntax for the file is basically bash syntax as it's really just a script that gets sourced by the main script. Hopefully I've commented it well enough that one can figure out what all the variables do.

Useage:
`sudo ./builder.sh <command>`

Commands:
* `clean` cleans everything out, so you can start fresh. It does leave the kernel and ramdisk targets alone though.
* `mount` mounts `procfs`, `sysfs`, etc for the chroot environment
* `unmount` unmounts `procfs`, `sysfs`, etc for the chroot environment
* `setup` creates the chroot environment and installs all necessary packages for the cross build into the chroot
* `update` updates the packages in the chroot to current versions
* `kernel <command>` commands that deal with the kernel as follows:
  * `get` download the kernel source code
  * `update` update the kernel source tree to the most current version
  * `build` create the kernel from the source code
  * `boot` boot the newly built kernel on the Nexus to try it out. Your nexus needs to be in fastboot/bootloader mode and plugged into your computer for this to work.
