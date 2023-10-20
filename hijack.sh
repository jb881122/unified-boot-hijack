#!/system/bin/sh

echo '[unified] Running unified boot hijack!' > /dev/kmsg

ORIG_KERN=0
HIJACK_DIR=/system/unified
BBX=$HIJACK_DIR/busybox

# Should we reboot and hijack the bootloader?
if ($BBX grep "#1 SMP PREEMPT Wed Oct 1 03:44:37 JST 2014" /proc/version); then
    ORIG_KERN=1
fi

if [ $ORIG_KERN -eq 1 ]; then
    # Disable SELinux (so we can write /dev/mem)
    echo "0" > /sys/fs/selinux/enforce

    # Boot recovery image?
    BOOT_RECOVERY=0

    # Flash keypad LED and do recovery if there are keypresses within that flash
    KEYPAD_LED=$(ls /sys/devices/leds-qpnp-*/leds/button-backlight/brightness)
    echo "1" > $KEYPAD_LED
    if ($BBX timeout 1 $BBX cat /dev/input/event7|read -r -N 1); then
        BOOT_RECOVERY=1
    fi
    echo "0" > $KEYPAD_LED

    # Select the file to patch aboot with
    if [ $BOOT_RECOVERY -eq 1 ]; then
        PART_2_FILE=aboot-patch-recovery.bin
        echo '[unified] Booting to recovery...' > /dev/kmsg
    else
        PART_2_FILE=aboot-patch-normal.bin
        echo '[unified] Booting normally...' > /dev/kmsg
    fi

    # Write our unified-boot hijack to memory
    $BBX dd if=$HIJACK_DIR/unified-header.bin of=/dev/mem bs=1024 seek=262140
    $BBX dd if=$HIJACK_DIR/$PART_2_FILE of=/dev/mem bs=1024 seek=524288
    $BBX dd if=$HIJACK_DIR/parsed-device-tree.bin of=/dev/mem bs=1024 seek=524290

    # Prevent accidentally triggering a reboot to download mode
    echo "0" > /sys/module/restart/parameters/download_mode

    # Reboot as quickly as possible
    echo "b" > /proc/sysrq-trigger

else
    echo '[unified] Non-original kernel already running, exiting...' > /dev/kmsg
fi
