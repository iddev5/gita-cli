#ifndef TOAST_H
#define TOAST_H

#include <stdint.h>

#define TOAST_INIT_ERROR -1
#define TOAST_SHOW_ERROR -2
#define TOAST_OK          1
#define TOAST_UNREACHABLE 2

#if __c_plus_plus
extern "C" {
#endif

int toast_init();
void toast_deinit();
int toast_show(uint16_t *text);

#if __c_plus_plus
};
#endif

#endif
