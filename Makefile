CC ?= arm-linux-androideabi-gcc
OBJCOPY ?= arm-linux-androideabi-objcopy

all: unified.zip

clean:
	-rm -rf unified.zip dist system obj


unified.zip: dist/unified.tar.gz dist/install-unified-hijack.sh \
		dist/aboot-new.img dist/boot-old.img dist/recovery-new.img \
		dist/boot-new.img
	zip -r -j unified.zip dist


dist/unified.tar.gz: dist system/busybox system/hijack.sh \
		system/parsed-device-tree.bin system/unified-header.bin \
		system/aboot-patch-normal.bin system/aboot-patch-recovery.bin
	tar -C system -czvf dist/unified.tar.gz .

dist/install-unified-hijack.sh: dist install-unified-hijack.sh
	cp install-unified-hijack.sh dist/

dist/aboot-new.img: dist aboot-new.img
	cp aboot-new.img dist/

dist/boot-old.img: dist boot-old.img
	cp boot-old.img dist/

dist/recovery-new.img: dist recovery-new.img
	cp recovery-new.img dist/

dist/boot-new.img: dist boot-new.img
	cp boot-new.img dist/

dist:
	mkdir -p dist


system/busybox: system busybox
	cp busybox system/

system/hijack.sh: system hijack.sh
	cp hijack.sh system/

system/parsed-device-tree.bin: system parsed-device-tree.bin
	cp parsed-device-tree.bin system/

system/unified-header.bin: system unified-header.bin
	cp unified-header.bin system/

system/aboot-patch-normal.bin: system obj/aboot-patch-normal.o
	$(OBJCOPY) -O binary obj/aboot-patch-normal.o system/aboot-patch-normal.bin
	truncate -s 2048 system/aboot-patch-normal.bin

system/aboot-patch-recovery.bin: system obj/aboot-patch-recovery.o
	$(OBJCOPY) -O binary obj/aboot-patch-recovery.o system/aboot-patch-recovery.bin
	truncate -s 2048 system/aboot-patch-recovery.bin

system:
	mkdir -p system


obj/aboot-patch-normal.o: obj aboot-patch.S
	$(CC) -c -DPARTITION_NAME=fota -o obj/aboot-patch-normal.o aboot-patch.S

obj/aboot-patch-recovery.o: obj aboot-patch.S
	$(CC) -c -DPARTITION_NAME=reserve3 -o obj/aboot-patch-recovery.o aboot-patch.S

obj:
	mkdir -p obj
