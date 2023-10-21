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
    ldr r8, cmp_pc_0_instr
    str r8, [r9]

    /* Change partition name */
    ldr r9, recovery_part_name
    adr r10, new_part_name
    bl patch_name

    /* Read ssd partition regardless of unlock status */
    ldr r9, is_unlocked_check
    ldr r8, cmp_r0_r0_instr
    str r8, [r9]
    ldr r9, is_tampered_check
    str r8, [r9]

    /* Jump back to the now-patched bootloader */
    ldr r9, bl_addr
    bx r9

patch_name:
    ldrb r8, [r10], #1
    strb r8, [r9], #1
    cmp r8, #0
    bne patch_name
    bx lr

.align

/* Offsets obtained from reverse-engineering the bootloader */
bl_addr:
    .word 0x0FF00000
unified_addr:
    .word 0x0FFFF000
use_signed_kernel:
    .word 0x0FF14724
recovery_part_name:
    .word 0x0FF3F004
boot_recovery_check:
    .word 0x0FF173A0
is_unlocked_check:
    .word 0x0FF17980
is_tampered_check:
    .word 0x0FF1798C

/* ARM instructions we use for patching */
cmp_pc_0_instr:
    .word 0xE35F0000
cmp_r0_r0_instr:
    .word 0xE1500000
mov_r0_0_instr:
    .word 0xE3A00000
bx_lr_instr:
    .word 0xE12FFF1E

/* Partition name to replace with (max 11 characters) */
new_part_name:
    .asciz STRINGIZE(PARTITION_NAME)
