// Copyright (C) 2026 noahbelton29
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, using version 3 of the License.

#ifndef VGA_H
#define VGA_H

#include "types.h"

#define VGA_BASE  0xB8000 // VGA text buffer address
#define VGA_COLS  80      // columns per row
#define VGA_ROWS  25      // rows on screen

#define COL_WHITE 0x0F    // white on black
#define COL_GREEN 0x0A    // bright green on black
#define COL_RED   0x0C    // bright red on black
#define COL_GREY  0x07    // grey on black

void vga_clear();
void vga_print(const char *str, uint8_t colour);
void vga_println(const char *str, uint8_t colour);
void vga_print_ok(const char *msg);
void vga_print_fail(const char *msg);

#endif