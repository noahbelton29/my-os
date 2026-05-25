#include "vga.h"
#include "gdt.h"

void kernel_main() {
    vga_clear();

    gdt_init();
    if (gdt_test()) {
        vga_print_ok("Initialised GDT");
    } else {
        vga_print_fail("GDT initialisation failed");
    }

    while (1);
}