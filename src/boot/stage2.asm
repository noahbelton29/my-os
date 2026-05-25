;; Copyright (C) 2026 noahbelton29
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, using version 3 of the License.

[BITS 16]
[ORG 0x7E00]

start:
    mov al, [0x7C00 + 510]             ; read drive number from stage 1
    mov [boot_drive], al               ; store it

    call clear_screen

    ;                                  ; hide cursor
    mov ah, 0x01                       ; set cursor shape function
    mov ch, 0x3F                       ; invisible cursor
    int 0x10

    call draw_menu                     ; draw the menu on startup

menu:
    call read_key                      ; wait for keypress
    cmp al, 0x00                       ; extended key? (arrow keys)
    je .extended
    cmp al, 0x0D                       ; enter key?
    je .select
    jmp menu                           ; unknown key, loop back

.extended:
    cmp ah, 0x48                       ; up arrow?
    je .move_up
    cmp ah, 0x50                       ; down arrow?
    je .move_down
    jmp menu

.move_up:
    mov al, [selected]
    cmp al, 0                          ; already at top?
    je menu                            ; if yes, do nothing
    dec byte [selected]                ; move selection up
    call draw_menu
    jmp menu

.move_down:
    mov al, [selected]
    cmp al, 2                          ; already at bottom?
    je menu                            ; if yes, do nothing
    inc byte [selected]                ; move selection down
    call draw_menu
    jmp menu

.select:
    mov al, [selected]
    cmp al, 0                          ; option 1 selected?
    je option1
    cmp al, 1                          ; option 2 selected?
    je option2
    cmp al, 2                          ; option 3 selected?
    je option3
    jmp menu

option1:
    ;                                  ; load and boot stage 3
    mov ah, 0x02                       ; read sectors function
    mov al, 0x01                       ; number of sectors to read
    mov ch, 0x00                       ; cylinder 0
    mov cl, 0x04                       ; sector 4 (stage 3)
    mov dh, 0x00                       ; head 0
    mov dl, [boot_drive]               ; drive number
    mov bx, 0x8000                     ; load into memory at 0x8000
    int 0x13
    jc .disk_error                     ; jump if error
    jmp 0x8000                         ; jump to stage 3

.disk_error:
    call clear_screen
    call move_cursor
    mov si, msg_disk_error             ; si = pointer to msg_disk_error
    call print
    call read_key                      ; wait for any key before going back
    mov byte [selected], 0             ; reset selection
    jmp start                          ; loop back to start

option2:
    ;                                  ; shutdown computer
    mov ax, 0x5301                     ; connect to APM interface
    xor bx, bx                         ; bx = 0
    int 0x15

    mov ax, 0x530E                     ; set APM version to 1.2
    xor bx, bx                         ; bx = 0
    mov cx, 0x0102
    int 0x15

    mov ax, 0x5307                     ; set power state
    mov bx, 0x0001                     ; all devices
    mov cx, 0x0003                     ; power off
    int 0x15

option3:
    jmp 0xFFFF:0x0000                  ; far jump to reset vector

.hang:
    hlt
    jmp .hang

; draw_menu
; redraws the menu, highlighting the selected option
draw_menu:
    call clear_screen

    ;                                  ; print title at row 0
    mov ah, 0x02                       ; set cursor position
    mov bh, 0x00                       ; page number 0
    mov dh, 0x00                       ; row 0
    mov dl, 0x00                       ; column 0
    int 0x10
    mov si, msg_title
    mov bl, 0x07                       ; normal colour
    call print_centered

    ;                                  ; print subtitle
    mov ah, 0x02                       ; set cursor position
    mov bh, 0x00                       ; page number 0
    mov dh, 0x17                       ; row 23
    mov dl, 0x00                       ; column 0
    int 0x10
    mov si, msg_subtitle
    mov bl, 0x07                       ; normal colour
    call print_centered

    ;                                  ; print footer
    mov ah, 0x02                       ; set cursor position
    mov bh, 0x00                       ; page number 0
    mov dh, 0x18                       ; row 24
    mov dl, 0x00                       ; column 0
    int 0x10
    mov si, msg_footer
    mov bl, 0x07                       ; normal colour
    call print_centered

    ;                                  ; draw option 1 bar
    mov dh, 0x0A                       ; row 10
    mov al, [selected]
    cmp al, 0                          ; is option 1 selected?
    je .bar1_highlighted
    mov bl, 0x07                       ; normal colour
    jmp .bar1_draw
.bar1_highlighted:
    mov bl, 0x70                       ; inverted colour
.bar1_draw:
    call draw_bar
    mov ah, 0x02                       ; set cursor position
    mov bh, 0x00                       ; page number 0
    mov dh, 0x0A                       ; row 10
    mov dl, 0x00                       ; column 0
    int 0x10
    mov si, msg
    call print_centered

    ;                                  ; draw option 2 bar
    mov dh, 0x0B                       ; row 11
    mov al, [selected]
    cmp al, 1                          ; is option 2 selected?
    je .bar2_highlighted
    mov bl, 0x07                       ; normal colour
    jmp .bar2_draw
.bar2_highlighted:
    mov bl, 0x70                       ; inverted colour
.bar2_draw:
    call draw_bar
    mov ah, 0x02                       ; set cursor position
    mov bh, 0x00                       ; page number 0
    mov dh, 0x0B                       ; row 11
    mov dl, 0x00                       ; column 0
    int 0x10
    mov si, msg2
    call print_centered

    ;                                  ; draw option 3 bar
    mov dh, 0x0C                       ; row 12
    mov al, [selected]
    cmp al, 2                          ; is option 3 selected?
    je .bar3_highlighted
    mov bl, 0x07                       ; normal colour
    jmp .bar3_draw
.bar3_highlighted:
    mov bl, 0x70                       ; inverted colour
.bar3_draw:
    call draw_bar
    mov ah, 0x02                       ; set cursor position
    mov bh, 0x00                       ; page number 0
    mov dh, 0x0C                       ; row 12
    mov dl, 0x00                       ; column 0
    int 0x10
    mov si, msg3
    call print_centered

    ret

; draw_bar
; fills an entire row with a colour attribute
; input: DH = row, BL = colour attribute
draw_bar:
    mov ah, 0x02                       ; set cursor position
    mov bh, 0x00                       ; page number 0
    mov dl, 0x00                       ; column 0
    int 0x10
    mov ah, 0x09                       ; print character with colour
    mov al, ' '                        ; space character
    mov bh, 0x00                       ; page number 0
    mov cx, 80                         ; fill all 80 columns
    int 0x10
    ret

; strlen
; returns the length of a string in CX
; input: SI = pointer to null-terminated string
strlen:
    mov cx, 0                          ; cx = length counter
.loop:
    lodsb                              ; load byte at DS:SI into AL
    test al, al                        ; null terminator?
    jz .done                           ; if yes, stop
    inc cx                             ; increment length
    jmp .loop
.done:
    ret

; print_centered
; prints a string centered on the current row
; input: SI = pointer to null-terminated string, BL = colour attribute
print_centered:
    push si                            ; save SI before strlen destroys it
    call strlen                        ; cx = string length
    pop si                             ; restore SI

    mov ax, 80                         ; screen width
    sub ax, cx                         ; ax = 80 - length
    shr ax, 1                          ; ax = (80 - length) / 2

    mov ah, 0x03                       ; get current cursor position
    mov bh, 0x00                       ; page number 0
    int 0x10                           ; dh = current row

    mov dl, al                         ; column = (80 - length) / 2
    mov ah, 0x02                       ; set cursor position
    mov bh, 0x00                       ; page number 0
    int 0x10

    call print_coloured                ; print with colour
    ret

; read_key
; returns ASCII key code of key pressed in AL
read_key:
    mov ah, 0x00                       ; wait for keypress function
    int 0x16                           ; bios keyboard interrupt
    ret

; move_cursor
; moves the cursor to the default position
move_cursor:
    mov ah, 0x02                       ; set cursor position function
    mov bh, 0x00                       ; page number 0
    mov dh, 0x00                       ; row 0
    mov dl, 0x00                       ; col 0
    int 0x10
    ret

; clear_screen
; clears the screen
clear_screen:
    mov ah, 0x06                       ; scroll up function
    mov al, 0x00                       ; clear entire screen
    mov bh, 0x07                       ; colour: light grey on black
    mov cx, 0x0000                     ; top left corner: row 0, col 0
    mov dx, 0x184F                     ; bottom right corner: row 24, col 79
    int 0x10
    ret

; print_num
; prints a 16 bit unsigned integer
; input: AX = number to print
print_num:
    mov cx, 0                          ; cx = digit counter
.divide_loop:
    cmp ax, 0                          ; no more digits?
    je .print_loop                     ; if yes, start printing
    xor dx, dx                         ; dx = 0
    mov bx, 10                         ; divisor
    div bx                             ; ax = ax / 10, dx = ax % 10
    add dl, '0'                        ; convert remainder to ASCII
    push dx                            ; push digit onto stack
    inc cx                             ; count the digit
    jmp .divide_loop
.print_loop:
    cmp cx, 0                          ; printed all digits?
    je .done                           ; if yes, stop
    pop dx                             ; pop digit off stack
    mov ah, 0x0E                       ; bios teletype function
    mov al, dl                         ; character to print
    int 0x10                           ; call bios video interrupt
    dec cx                             ; decrement digit counter
    jmp .print_loop
.done:
    ret

; print_coloured
; prints a message to the screen with a colour attribute
; input: SI = pointer to null-terminated string, BL = colour attribute
print_coloured:
    lodsb                              ; load byte at DS:SI into AL, then increment SI
    test al, al                        ; check for null terminator
    jz .done                           ; if yes, stop
    mov ah, 0x09                       ; print character with colour function
    mov bh, 0x00                       ; page number 0
    mov cx, 0x01                       ; print once
    int 0x10                           ; call bios video interrupt
    mov ah, 0x03                       ; get cursor position
    mov bh, 0x00                       ; page number 0
    int 0x10                           ; dx now holds row/col
    inc dl                             ; move cursor right one column
    mov ah, 0x02                       ; set cursor position
    mov bh, 0x00                       ; page number 0
    int 0x10                           ; update cursor
    jmp print_coloured
.done:
    ret

; print
; prints a message to the screen
; input: SI = pointer to null-terminated string
print:
    lodsb                              ; load byte at DS:SI into AL, then increment SI
    test al, al                        ; check for null terminator
    jz .done                           ; if yes, stop
    mov ah, 0x0E                       ; bios teletype function
    int 0x10                           ; call bios video interrupt
    jmp print
.done:
    ret

boot_drive     db 0
msg_title      db "Bootloader v0.1", 0
msg_subtitle   db "Made by Noah Belton", 0
msg_footer     db "Use arrow keys to navigate, Enter to select", 0
msg_disk_error db "Disk error! Press any key to return.", 0
selected       db 0
msg            db "1. Boot OS", 0
msg2           db "2. Shutdown", 0
msg3           db "3. Reboot", 0

times 1024 - ($ - $$) db 0