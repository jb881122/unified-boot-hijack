#!/system/bin/sh
# Unified boot hijack installation (/system portion)

FILE_DROP_DIR=/data/local/tmp
HIJACK_DIR=/system/unified
HIJACKED_FILE=/system/etc/init.qcom.bt.sh

# Get ready to modify /system
setenforce 0
mount -o remount,rw /system

# Make sure we can run all needed commands
BBX=$FILE_DROP_DIR/busybox
chmod 755 $BBX

# Escape $HIJACK_DIR for sed
HIJACK_DIR_ESC=$(echo "$HIJACK_DIR"|$BBX sed 's/\//\\\//g')

# Uninstall hijack if already installed
if [ -e $HIJACK_DIR ]; then
    $BBX sed -i "/$HIJACK_DIR_ESC/d" $HIJACKED_FILE
    rm -rf $HIJACK_DIR
fi

# Create hijack directory and extract files to it
mkdir $HIJACK_DIR
$BBX tar xzvf $FILE_DROP_DIR/unified.tar.gz -C $HIJACK_DIR/
cp $BBX $HIJACK_DIR/busybox

# Set permissions & contexts
chown -R 0:0 $HIJACK_DIR
chmod 755 $HIJACK_DIR
chmod 644 $HIJACK_DIR/*
chmod 755 $HIJACK_DIR/*.sh $HIJACK_DIR/busybox
chcon 'u:object_r:system_file:s0' $HIJACK_DIR $HIJACK_DIR/*

# Hook into the hijacked file
$BBX sed -ri 's/(#!\/system\/bin\/sh)/\1\n'"$HIJACK_DIR_ESC"'\/hijack.sh/' $HIJACKED_FILE

# Undo system-wide security changes
mount -o remount,ro /system
setenforce 1
