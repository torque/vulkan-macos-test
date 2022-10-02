#include "swift.h"
#include "c.h"

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

#include <MoltenVK/mvk_vulkan.h>

// lol who needs a header tho for real dog
#include "cube/cube.c"

struct demo_context {
    struct demo demo;
    int argc;
    char **argv;
};

int main(int argc, char **argv) {
    struct demo_context ctx = {.argc = argc, .argv = argv};

    swift_launch_app(&ctx);
}

void demo_setup(struct demo_context *const ctx, void *const caMetalLayer) {
    demo_main(&ctx->demo, caMetalLayer, ctx->argc, (const char **)ctx->argv);
}

void demo_redraw(struct demo_context *const ctx) {
    demo_draw(&ctx->demo);
}
