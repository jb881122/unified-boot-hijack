#define STRINGIZE(s) STRINGIZE_SUB(s)
#define STRINGIZE_SUB(s) #s

.text

start:
    /* Mess up the unified-boot magic number (to avoid an infinite loop) */
    mov r8, #0
    ldr r9, unified_addr
    str r8, [r9]

    /* Make use_signed_kernel() return 0 (to bypass signature checks) */
    ldr r9, use_signed_kernel
    ldr r8, mov_r0_0_instr
    str r8, [r9], #4
    ldr r8, bx_lr_instr
    str r8, [r9]

    /* Always boot to recovery (so we can patch the longer partition name) */
    ldr r9, boot_recovery_check
    ldr r8, nop_instr
    str r8, [r9]

    /* Change partition name */
    ldr r9, recovery_part_name
    adr r10, new_part_name
    bl patch_name

    /* Jump back to the now-patched bootloader */
    /* Do this as a call because it may return if it fails */
    ldr r9, boot_linux_from_emmc
    blx r9

    /* We failed, halt the system now to avoid bootloops or strange behavior */
    b .

patch_name:
    ldrb r8, [r10], #1
    strb r8, [r9], #1
    cmp r8, #0
    bne patch_name
    bx lr

.align

/* Offsets obtained from reverse-engineering the bootloader */
boot_linux_from_emmc:
    .word 0x0FF1244C
unified_addr:
    .word 0x0FFFF000
use_signed_kernel:
    .word 0x0FF10238
recovery_part_name:
    .word 0x0FF330A8
boot_recovery_check:
    .word 0x0FF12498

/* ARM instructions we use for patching */
nop_instr:
    .word 0xE1A00000
mov_r0_0_instr:
    .word 0xE3A00000
bx_lr_instr:
    .word 0xE12FFF1E

/* Partition name to replace with (max 11 characters) */
new_part_name:
    .asciz STRINGIZE(PARTITION_NAME)
