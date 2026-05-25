// Copyright (C) 2026 noahbelton29
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, using version 3 of the License.

#include "gdt.h"

#define GDT_ENTRIES 5

static gdt_entry_t gdt[GDT_ENTRIES];
static gdt_descriptor_t gdt_desc;

// gdt_set_entry
// fills one GDT entry
static void gdt_set_entry(int i, uint32_t base, uint32_t limit, uint8_t access, uint8_t granularity) {
    gdt[i].base_low    = base & 0xFFFF;       // lower 16 bits of base
    gdt[i].base_mid    = (base >> 16) & 0xFF; // middle 8 bits of base
    gdt[i].base_high   = (base >> 24) & 0xFF; // upper 8 bits of base
    gdt[i].limit_low   = limit & 0xFFFF;      // lower 16 bits of limit
    gdt[i].granularity = (granularity & 0xF0) // upper flags nibble
        | ((limit >> 16) & 0x0F);             // upper 4 bits of limit
    gdt[i].access      = access;              // access byte
}

// gdt_load
// loads the GDT descriptor and reloads segment registers
extern void gdt_load(gdt_descriptor_t *desc);

void gdt_init() {
    gdt_set_entry(0, 0, 0,       0x00, 0x00); // null descriptor
    gdt_set_entry(1, 0, 0xFFFFF, 0x9A, 0xAF); // 64-bit code: present, ring 0, executable, L bit
    gdt_set_entry(2, 0, 0xFFFFF, 0x92, 0xAF); // 64-bit data: present, ring 0, writable
    gdt_set_entry(3, 0, 0xFFFFF, 0xFA, 0xAF); // 64-bit user code: present, ring 3, executable
    gdt_set_entry(4, 0, 0xFFFFF, 0xF2, 0xAF); // 64-bit user data: present, ring 3, writable

    gdt_desc.limit = sizeof(gdt) - 1; // size of GDT minus 1
    gdt_desc.base  = (uint64_t)&gdt; // address of GDT

    gdt_load(&gdt_desc); // load and reload segments
}

// gdt_test
// verifies the GDT loaded correctly by reading back the descriptor
// returns 1 on pass, 0 on fail
int gdt_test() {
    uint8_t gdtr[10];
    __asm__ volatile ("sgdt %0" : "=m"(gdtr)); // store GDT descriptor

    uint16_t limit = *(uint16_t *)&gdtr[0];    // first 2 bytes = limit
    if (limit == 0 || limit < 39) return 0;    // 5 entries * 8 bytes - 1 = 39

    return 1;
}