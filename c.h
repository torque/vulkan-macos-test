#ifndef C_DOT_H
#define C_DOT_H

struct demo_context;

void demo_setup(struct demo_context *const ctx, void *const caMetalLayer);
void demo_redraw(struct demo_context *const ctx);

#endif // C_DOT_H
