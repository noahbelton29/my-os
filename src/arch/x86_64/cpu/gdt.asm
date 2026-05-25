; gdt_load
; loads a new GDT and reloads all segment registers
; input: RDI = pointer to gdt_descriptor_t
global gdt_load
gdt_load:
    lgdt [rdi]                         ; load GDT from descriptor pointer

    ;                                  ; reload code segment via a far return
    ;                                  ; retfq pops RIP first, then CS
    lea rax, [rel .reload]             ; address to jump to after reload
    push 0x08                          ; push CS selector (popped second by retfq)
    push rax                           ; push RIP (popped first by retfq)
    retfq                              ; far return: pops RIP then CS

.reload:
    mov ax, 0x10                       ; 64-bit data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ret