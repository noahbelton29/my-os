// Copyright (C) 2026 noahbelton29
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, using version 3 of the License.

#ifndef GDT_H
#define GDT_H

#include "../../../kernel/types.h"

typedef struct {
    uint16_t limit_low;               // lower 16 bits of segment limit
    uint16_t base_low;                // lower 16 bits of base address
    uint8_t  base_mid;                // middle 8 bits of base address
    uint8_t  access;                  // access flags
    uint8_t  granularity;             // upper 4 bits of limit + flags
    uint8_t  base_high;               // upper 8 bits of base address
} __attribute__((packed)) gdt_entry_t;

typedef struct {
    uint16_t limit;                        // size of GDT in bytes minus 1
    uint64_t base;                         // linear address of GDT
} __attribute__((packed)) gdt_descriptor_t;

void gdt_init();
int gdt_test();

#endif