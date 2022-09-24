#include "swift.h"
#include "c.h"

#include <stdio.h>
#include <stdint.h>

int main(int argc, char **argv) {
    puts("main");

    swift_launch_app();

    printf("wow: %d\n", 10);
}

void print_int(int val) {
    printf("int: %d\n", val);
}
