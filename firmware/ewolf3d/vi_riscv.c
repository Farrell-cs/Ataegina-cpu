#include "wl_def.h"
#include <stdint.h>

#define VRAM      ((volatile uint8_t*)0x80000000)
#define BUTTONS   (*(volatile uint32_t*)0x80010000)
#define TIMER_MS  (*(volatile uint32_t*)0x80010004)

#define SCREEN_W  320
#define SCREEN_H  180

byte framebuffer[128 * 64 / 2];

static uint32_t time_offset = 0;

void TimerInit(void) {
    time_offset = TIMER_MS;
}

uint32_t get_TimeCount(void) {
    uint32_t elapsed_ms = TIMER_MS - time_offset;
    return (elapsed_ms * 70U) / 1000U;
}

void set_TimeCount(uint32_t t) {
    time_offset = TIMER_MS - ((t * 1000U) / 70U);
}

void WaitVBL(int n) {
    uint32_t target = get_TimeCount() + (uint32_t)n;
    while ((int32_t)(get_TimeCount() - target) < 0) {
        /* wait */
    }
}

void INL_Update(void) {
    static int old_btn = 0;
    uint32_t raw = BUTTONS & 0x7;
    int btn = 0;

    if (raw == 0x5) {
        btn = 0x10; /* BTN0 + BTN2 = Shoot / Use */
    } else {
        if (raw & 0x2) btn |= 0x01; /* BTN1 = Up/Forward */
        if (raw & 0x1) btn |= 0x04; /* BTN0 = Left */
        if (raw & 0x4) btn |= 0x08; /* BTN2 = Right */
    }

    static const byte scancodes[5] = {
        sc_UpArrow, sc_DownArrow, sc_LeftArrow, sc_RightArrow, sc_Space
    };
    int changed = btn ^ old_btn;
    old_btn = btn;
    for (int i = 0; i < 5; i++) {
        int mask = 1 << i;
        if (changed & mask) {
            keyboard_handler(scancodes[i], (old_btn & mask) != 0);
        }
    }
}

static inline uint8_t gray4_to_rgb332(uint8_t g4) {
    uint8_t r = (g4 >> 1) & 0x7;
    uint8_t g = (g4 >> 1) & 0x7;
    uint8_t b = (g4 >> 2) & 0x3;
    return (uint8_t)((r << 5) | (g << 2) | b);
}

void VL_Startup(void) {
    for (int i = 0; i < SCREEN_W * SCREEN_H; i++) {
        VRAM[i] = 0x00;
    }
}

void VL_Shutdown(void) {}

void VW_UpdateScreen(void) {
    /* Scale 128x64 4-bit framebuffer 2x -> 256x128 centered in 320x180 VRAM */
    const int x_off = (SCREEN_W - 256) / 2;
    const int y_off = (SCREEN_H - 128) / 2;

    for (int y = 0; y < 64; y++) {
        int row0 = (y_off + y * 2) * SCREEN_W + x_off;
        int row1 = row0 + SCREEN_W;
        for (int x = 0; x < 64; x++) {
            uint8_t packed = framebuffer[y * 64 + x];
            uint8_t c0 = gray4_to_rgb332((packed >> 4) & 0xF);
            uint8_t c1 = gray4_to_rgb332(packed & 0xF);
            int px = x * 4;
            VRAM[row0 + px]     = c0; VRAM[row0 + px + 1] = c0;
            VRAM[row1 + px]     = c0; VRAM[row1 + px + 1] = c0;
            VRAM[row0 + px + 2] = c1; VRAM[row0 + px + 3] = c1;
            VRAM[row1 + px + 2] = c1; VRAM[row1 + px + 3] = c1;
        }
    }
}

void Quit(const char *error) {
    (void)error;
    while (1) {}
}

int main(int argc, char **argv) {
    TimerInit();
    return WolfMain(argc, argv);
}
