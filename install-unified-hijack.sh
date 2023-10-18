#!/bin/bash

# Double-slashes are used in some spots so MSYS shells don't try converting the paths
FILE_DROP_PATH=//data/local/tmp

# Install /system hijack
adb push unified.tar.gz $FILE_DROP_PATH/
adb push install.sh $FILE_DROP_PATH/
adb shell su -c "chmod 755 $FILE_DROP_PATH/install.sh"
adb shell su -c "$FILE_DROP_PATH/install.sh"

# Flash partitions
adb reboot bootloader
fastboot wait-for-device
fastboot flash aboot aboot-new.img
fastboot flash boot boot-old.img
fastboot flash recovery boot-old.img
fastboot flash reserve3 recovery-new.img
fastboot flash fota boot-new.img

# Reboot
fastboot reboot
