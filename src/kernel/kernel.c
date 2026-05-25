// Copyright (C) 2026 noahbelton29
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, using version 3 of the License.

void kernel_main() {
    volatile char *vga = (volatile char *)0xB8000;
    const char *msg = "Hello from C!";
    int i = 0;

    // clear screen
    for (int j = 0; j < 80 * 25 * 2; j++) {
        vga[j] = 0;
    }

    // print message
    while (msg[i] != 0) {
        vga[i * 2]     = msg[i];
        vga[i * 2 + 1] = 0x0F;
        i++;
    }

    // halt
    while (1);
}