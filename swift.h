#ifndef TEST_SWIFT_H
#define TEST_SWIFT_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "c.h"

typedef struct demo_context swift_demo_context;

void swift_launch_app(struct demo_context *ctx);

#endif // TEST_SWIFT_H
