# Unified Boot Hijack

This repository is a proof-of-concept for exploitation of the unified boot mode built into the Android bootloader in order to boot custom kernels.

## What to Expect

**WARNING:** This is currently intended for the Kyocera DuraForce E6560 (AT&T) ONLY. Running it on any other phone will likely cause it to become a permenent brick. Bricking your device is not completely impossible regardless if something goes wrong. You have been warned; I am not responsible for what happens.

The riskiest operation is when the `aboot` partition is flashed. To be cautious, make sure its CRC32 is `8d24ee32` before doing anything else.

This isn't a bootloader unlock, but it will be about as close as you can get in many cases. This allows custom boot and recovery images to be booted from the device's EMMC memory. By default, TWRP is installed along with the stock boot image with a recompiled kernel.

Quirks / Things to keep in mind:

- After running this hijack, the boot image will be booted from the `fota` partition and the recovery image will be booted from the `reserve3` partition. If you flash new boot/recovery images, flash them there or else you will fail signature verification for custom images.
- The boot sequence involves rebooting from an old signed/authorized boot image when the hijack takes place, so it will look like the device is booting twice. This is normal and expected.
- Booting to recovery mode by any usual means will not work. To boot to recovery mode, toggle any non-Power key while the keypad is illuminated just before the device reboots itself.
- Since this hijacks a script in the `system` partition, if you flash anything to that partition, you will need to make sure that partition includes the hijack before rebooting.

Likely fixed in v0.3:

- This doesn't work 100% of the time. Sometimes, especially after rebooting, you may end up with a black screen with a green LED. To get out of this, force-reboot into fastboot mode and use `fastboot boot` to load an image. To help avoid this, power the phone off and on instead of rebooting.

## How to Use

Either Linux or Windows can be used here.

Prerequisites:

- ADB & Fastboot (platform tools)
- Fastboot drivers for your device (if needed)
- The latest stock ROM installed & rooted
- USB debugging enabled & authorized
- Some way to unzip files
- Bash

Steps:

- Download the appropriate ZIP file from the releases page
- Extract the ZIP into a working directory
- Go to that directory in Bash
- Plug your device in and make sure USB debugging is functional
- Run `./install-unified-hijack.sh`
- If it worked, watch your device reboot into a new kernel

## How to Compile

It is best to do this in Linux, because I have not tested any of this on Windows.

Prerequisites:
- `arm-linux-androideabi-gcc` and `arm-linux-androideabi-objcopy` (the NDK provides these; I used GCC 4.8)
- `make`
- `tar`
- `zip`
- `truncate`
- `git` (only if you plan on cloning this repository)

Steps:
- Clone or otherwise get the repository's files into a directory.
- Go to that directory
- Run `CC=arm-linux-androideabi-gcc OBJCOPY=arm-linux-androideabi-objcopy make` (adding paths to the CC and OBJCOPY variables if needed)

If it came together correctly, you should find `unified.zip` in the repository directory.

## How it Works

When the `boot_linux_from_emmc` function is called in the Android bootloader, one of the first things that happens is that a check is performed for an already-loaded boot image header at a certain memory address. If that check passes, all loading and checking of the boot image is bypassed and the bootloader proceeds to try booting.

This hijack uses the fact that memory is not cleared on reboot to make the bootloader run arbitrary code that patches and re-runs itself. Specifically, a signed image is booted first. Then, a header is loaded into the expected address, a kernel and already-parsed device tree are loaded into appropriate addresses, and a reboot is performed.

After the reboot, the bootloader finds a valid header for unified boot and runs our code. Then:
- The header magic is changed to avoid running our code again
- Security checks are disabled by making the `use_signed_kernel` function return 0
- Recovery boot is forced (to allow more room for the partition name since "recovery" is a long name)
- The partition name is patched to allow booting from a non-previously-checked partition
- Finally, the now-patched bootloader is ran again.

## Room for Improvement

- Adapting this to other devices (especially Kyocera devices from a similar era, as it would likely require few changes to make it work).
- Allowing booting to recovery in normal ways. The issue here is that if the same boot image is booted from either the boot or recovery partitions, they are virtually indistinguishable once booted. This could be resolved by using two different images, but they both have to be signed and the newer stock image has stricter SELinux restrictions which make it more difficult for the hijack to work.
- Re-doing this in a compiled language (possibly as a kernel module?). Although I haven't seen any problems writing memory on a running system and rebooting right away, there is a possibility that it might get corrupted before the reboot, breaking the hijack and causing a reboot loop.
- Being able to run ROMs with `/system` mounted in some other location, which could allow repartitioning so that if that partition is formatted, the hijack won't cease to work

## Licensing

Anything not covered by another license is hereby released into the public domain.

This repository (specifically the `*.img` files) contains components from Kyocera, for which licensing details and source code downloads may be found at https://kyoceramobile.com/support/developers/.
