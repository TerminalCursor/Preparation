%define FREE_SPACE 0x9000
longmode:
    call check_cpu
    jc .NoLongMode

    mov edi, FREE_SPACE
    jmp SwitchToLongMode

[bits 64]
.Long:
    hlt
    jmp .Long

[bits 16]
.NoLongMode:
    mov si, NoLongMode
    call Print

.Die:
    hlt
    jmp .Die

%include "BootLibrary/LongModeDirectly.asm"

[bits 16]

NoLongMode db "ERROR: CPU does not support long mode.", 0x0A, 0x0D, 0

check_cpu:
        ; Check whether CPUID is supported or not.
    pushfd                            ; Get flags in EAX register.

    pop eax
    mov ecx, eax
    xor eax, 0x200000
    push eax
    popfd

    pushfd
    pop eax
    xor eax, ecx
    shr eax, 21
    and eax, 1                        ; Check whether bit 21 is set or not. If EAX now contains 0, CPUID isn't supported.
    push ecx
    popfd

    test eax, eax
    jz .NoLongMode

    mov eax, 0x80000000
    cpuid

    cmp eax, 0x80000001               ; Check whether extended function 0x80000001 is available are not.
    jb .NoLongMode                    ; If not, long mode not supported.

    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29                 ; Test if the LM-bit, is set or not.
    jz .NoLongMode                    ; If not Long mode not supported.

    ret

.NoLongMode:
    stc
    ret

; Prints out a message using the BIOS.

; es:si    Address of ASCIIZ string to print.

Print:
    pushad
.PrintLoop:
    lodsb                             ; Load the value at [@es:@si] in @al.
    test al, al                       ; If AL is the terminator character, stop printing.
    je .PrintDone
    mov ah, 0x0E
    int 0x10
    jmp .PrintLoop                    ; Loop till the null character not found.

.PrintDone:
    popad                             ; Pop all general purpose registers to save them.
    ret
