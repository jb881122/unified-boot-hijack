CC ?= arm-linux-androideabi-gcc
OBJCOPY ?= arm-linux-androideabi-objcopy

all: unified.zip

clean:
	-rm -rf unified.zip dist system obj


unified.zip: dist/unified.tar.gz dist/install-unified-hijack.sh \
		dist/aboot-new.img dist/boot-old.img dist/recovery-new.img \
		dist/boot-new.img dist/install.sh-internal
	zip -r -j unified.zip dist


dist/unified.tar.gz: system/busybox system/hijack.sh \
		system/parsed-device-tree.bin system/unified-header.bin \
		system/aboot-patch-normal.bin system/aboot-patch-recovery.bin \
		| dist
	tar -C system -czvf dist/unified.tar.gz .

dist/install-unified-hijack.sh: install-unified-hijack.sh | dist
	cp install-unified-hijack.sh dist/

dist/aboot-new.img: aboot-new.img | dist
	cp aboot-new.img dist/

dist/boot-old.img: boot-old.img | dist
	cp boot-old.img dist/

dist/recovery-new.img: recovery-new.img | dist
	cp recovery-new.img dist/

dist/boot-new.img: boot-new.img | dist
	cp boot-new.img dist/

dist/install.sh-internal: install.sh | dist
	cp install.sh dist/install.sh-internal

dist:
	mkdir -p dist


system/busybox: busybox | system
	cp busybox system/

system/hijack.sh: hijack.sh | system
	cp hijack.sh system/

system/parsed-device-tree.bin: parsed-device-tree.bin | system
	cp parsed-device-tree.bin system/

system/unified-header.bin: unified-header.bin | system
	cp unified-header.bin system/

system/aboot-patch-normal.bin: obj/aboot-patch-normal.o | system
	$(OBJCOPY) -O binary obj/aboot-patch-normal.o system/aboot-patch-normal.bin
	truncate -s 2048 system/aboot-patch-normal.bin

system/aboot-patch-recovery.bin: obj/aboot-patch-recovery.o | system
	$(OBJCOPY) -O binary obj/aboot-patch-recovery.o system/aboot-patch-recovery.bin
	truncate -s 2048 system/aboot-patch-recovery.bin

system:
	mkdir -p system


obj/aboot-patch-normal.o: aboot-patch.S | obj
	$(CC) -c -DPARTITION_NAME=fota -o obj/aboot-patch-normal.o aboot-patch.S

obj/aboot-patch-recovery.o: aboot-patch.S | obj
	$(CC) -c -DPARTITION_NAME=reserve3 -o obj/aboot-patch-recovery.o aboot-patch.S

obj:
	mkdir -p obj

.PHONY: all clean
