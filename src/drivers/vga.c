// Copyright (C) 2026 noahbelton29
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, using version 3 of the License.

#include "vga.h"

static volatile char *vga = (volatile char *)VGA_BASE; // VGA buffer pointer
static int cursor_row     = 0;                         // current row
static int cursor_col     = 0;                         // current column

// vga_clear
// clears the screen and resets the cursor
void vga_clear() {
    for (int i = 0; i < VGA_COLS * VGA_ROWS * 2; i++) {
        vga[i] = 0; // zero out character and attribute bytes
    }
    cursor_row = 0;
    cursor_col = 0;
}

// vga_putchar
// writes a single character at the current cursor position
static void vga_putchar(char c, uint8_t colour) {
    // newline move to next row
    if (c == '\n') {
        cursor_row++;
        cursor_col = 0;
        return;
    }

    int offset        = (cursor_row * VGA_COLS + cursor_col) * 2;
    vga[offset]       = c;      // character byte
    vga[offset + 1]   = colour; // attribute byte
    cursor_col++;

    // wrap to next row
    if (cursor_col >= VGA_COLS) {
        cursor_col = 0;
        cursor_row++;
    }
}

// vga_print
// prints a null-terminated string in the given colour
void vga_print(const char *str, uint8_t colour) {
    for (int i = 0; str[i] != 0; i++) {
        vga_putchar(str[i], colour);
    }
}

// vga_println
// prints a string followed by a newline
void vga_println(const char *str, uint8_t colour) {
    vga_print(str, colour);
    vga_putchar('\n', colour);
}

// vga_print_ok
// prints "[ OK ] <msg>" in the style of a boot log
void vga_print_ok(const char *msg) {
    vga_print("[", COL_GREY);
    vga_print(" OK ", COL_GREEN);
    vga_print("] ", COL_GREY);
    vga_println(msg, COL_WHITE);
}

// vga_print_fail
// prints "[ FAIL ] <msg>" in red
void vga_print_fail(const char *msg) {
    vga_print("[", COL_GREY);
    vga_print("FAIL", COL_RED);
    vga_print("] ", COL_GREY);
    vga_println(msg, COL_WHITE);
}