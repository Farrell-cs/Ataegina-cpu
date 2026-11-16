#include <stdint.h>

#define VRAM     ((volatile uint8_t*)0x80000000)
#define BUTTONS  (*(volatile uint32_t*)0x80010000)

#define SCREEN_W 1280
#define SCREEN_H 720
#define MAX_ITER 200

typedef int32_t fix16_t;

#define FRAC_BITS       16
#define ONE             ((fix16_t)(1 << FRAC_BITS))
#define BAILOUT         ((fix16_t)(4 << FRAC_BITS))
#define FLOAT_TO_FIX(x) ((fix16_t)((x) * (double)ONE))

static inline fix16_t fix_mul(fix16_t a, fix16_t b) {
    return (fix16_t)(((int64_t)a * (int64_t)b) >> FRAC_BITS);
}

static uint8_t iter_to_rgb332(int iter) {
    if (iter >= MAX_ITER) {
        return 0x00; // Black inside the set
    }
    uint8_t r = (uint8_t)((iter * 7) / MAX_ITER);
    uint8_t g = (uint8_t)(((iter * 2) & 0x07));
    uint8_t b = (uint8_t)(3 - ((iter * 3) / MAX_ITER));
    return (uint8_t)((r << 5) | (g << 2) | (b & 0x03));
}

static void render_mandelbrot(fix16_t x_min, fix16_t x_max, fix16_t y_min, fix16_t y_max) {
    fix16_t dx = (x_max - x_min) / SCREEN_W;
    fix16_t dy = (y_max - y_min) / SCREEN_H;

    fix16_t ci = y_min;
    for (int py = 0; py < SCREEN_H; py++) {
        int row_offset = py * SCREEN_W;
        fix16_t cr = x_min;

        for (int px = 0; px < SCREEN_W; px++) {
            fix16_t zr = 0;
            fix16_t zi = 0;
            int iter = 0;

            while (iter < MAX_ITER) {
                fix16_t zr2 = fix_mul(zr, zr);
                fix16_t zi2 = fix_mul(zi, zi);

                if ((zr2 + zi2) > BAILOUT) {
                    break;
                }

                fix16_t zr_new = zr2 - zi2 + cr;
                fix16_t zi_new = (fix_mul(zr, zi) << 1) + ci;

                zr = zr_new;
                zi = zi_new;
                iter++;
            }

            VRAM[row_offset + px] = iter_to_rgb332(iter);
            cr += dx;
        }
        ci += dy;
    }
}

int main(void) {
    fix16_t x_min = FLOAT_TO_FIX(-2.2);
    fix16_t x_max = FLOAT_TO_FIX( 1.0);
    fix16_t y_min = FLOAT_TO_FIX(-1.1);
    fix16_t y_max = FLOAT_TO_FIX( 1.1);

    render_mandelbrot(x_min, x_max, y_min, y_max);

    while (1) {
        // Hold rendered frame
    }
    return 0;
}
