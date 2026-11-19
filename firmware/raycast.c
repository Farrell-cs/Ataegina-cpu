#include <stdint.h>

#define VRAM     ((volatile uint8_t*)0x80000000)
#define BUTTONS  (*(volatile uint32_t*)0x80010000)

#define SCREEN_W 320
#define SCREEN_H 180
#define MAP_W    8
#define MAP_H    8

typedef int32_t fix16_t;

#define ONE             ((fix16_t)(1 << 16))
#define HALF            ((fix16_t)(1 << 15))
#define FLOAT_TO_FIX(x) ((fix16_t)((x) * 65536.0))

static inline fix16_t fix_mul(fix16_t a, fix16_t b) {
    return (fix16_t)(((int64_t)a * (int64_t)b) >> 16);
}

// 1.0 / abs(x) in Q16.16 using only 32-bit hardware DIV
static inline fix16_t fix_inv_abs(fix16_t x) {
    fix16_t ax = (x < 0) ? -x : x;
    if (ax < 256) {
        return 0x10000000;
    }
    return ((int32_t)(1 << 24) / ax) << 8;
}

static uint8_t world_map[MAP_H][MAP_W] = {
    {1, 1, 1, 1, 1, 1, 1, 1},
    {1, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 2, 0, 0, 3, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 4, 4, 0, 0, 1},
    {1, 0, 3, 0, 0, 2, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 1, 1, 1, 1, 1, 1}
};

static uint8_t wall_color(uint8_t tile, int side) {
    switch (tile) {
        case 1:  return side ? 0x80 : 0xE0; // Red brick
        case 2:  return side ? 0x0A : 0x1F; // Cyan pillar
        case 3:  return side ? 0x0C : 0x1C; // Green block
        default: return side ? 0x90 : 0xFC; // Yellow/gold block
    }
}

static void render_frame(fix16_t pos_x, fix16_t pos_y,
                         fix16_t dir_x, fix16_t dir_y,
                         fix16_t plane_x, fix16_t plane_y) {
    for (int x = 0; x < SCREEN_W; x++) {
        // camera_x in [-1.0, +1.0] in Q16.16: (2 * x / SCREEN_W) - 1
        fix16_t cam_x = ((x << 17) / SCREEN_W) - ONE;

        fix16_t ray_dx = dir_x + fix_mul(plane_x, cam_x);
        fix16_t ray_dy = dir_y + fix_mul(plane_y, cam_x);

        int map_x = pos_x >> 16;
        int map_y = pos_y >> 16;

        fix16_t delta_x = fix_inv_abs(ray_dx);
        fix16_t delta_y = fix_inv_abs(ray_dy);

        int step_x, step_y;
        fix16_t side_x, side_y;

        if (ray_dx < 0) {
            step_x = -1;
            side_x = fix_mul(pos_x - (map_x << 16), delta_x);
        } else {
            step_x = 1;
            side_x = fix_mul(((map_x + 1) << 16) - pos_x, delta_x);
        }

        if (ray_dy < 0) {
            step_y = -1;
            side_y = fix_mul(pos_y - (map_y << 16), delta_y);
        } else {
            step_y = 1;
            side_y = fix_mul(((map_y + 1) << 16) - pos_y, delta_y);
        }

        uint8_t hit = 0;
        int side = 0;

        for (int steps = 0; steps < 16 && hit == 0; steps++) {
            if (side_x < side_y) {
                side_x += delta_x;
                map_x  += step_x;
                side    = 0;
            } else {
                side_y += delta_y;
                map_y  += step_y;
                side    = 1;
            }
            if (map_x >= 0 && map_x < MAP_W && map_y >= 0 && map_y < MAP_H) {
                hit = world_map[map_y][map_x];
            } else {
                hit = 1;
            }
        }

        fix16_t perp_dist = (side == 0) ? (side_x - delta_x) : (side_y - delta_y);
        if (perp_dist < 4096) {
            perp_dist = 4096;
        }

        int line_h = (int)((SCREEN_H << 16) / perp_dist);
        int draw_start = (SCREEN_H - line_h) >> 1;
        int draw_end   = (SCREEN_H + line_h) >> 1;
        if (draw_start < 0) draw_start = 0;
        if (draw_end >= SCREEN_H) draw_end = SCREEN_H - 1;

        uint8_t col = wall_color(hit, side);

        for (int y = 0; y < SCREEN_H; y++) {
            uint8_t px;
            if (y < draw_start) {
                px = 0x25; // Dark slate ceiling
            } else if (y <= draw_end) {
                px = col;  // Shaded 3D wall
            } else {
                px = 0x49; // Dark grey floor
            }
            VRAM[y * SCREEN_W + x] = px;
        }
    }
}

static void rotate(fix16_t *dx, fix16_t *dy, fix16_t *px, fix16_t *py,
                   fix16_t cos_a, fix16_t sin_a) {
    fix16_t old_dx = *dx;
    *dx = fix_mul(old_dx, cos_a) - fix_mul(*dy, sin_a);
    *dy = fix_mul(old_dx, sin_a) + fix_mul(*dy, cos_a);

    fix16_t old_px = *px;
    *px = fix_mul(old_px, cos_a) - fix_mul(*py, sin_a);
    *py = fix_mul(old_px, sin_a) + fix_mul(*py, cos_a);
}

int main(void) {
    fix16_t pos_x   = FLOAT_TO_FIX(1.5);
    fix16_t pos_y   = FLOAT_TO_FIX(1.5);
    fix16_t dir_x   = FLOAT_TO_FIX(0.866);
    fix16_t dir_y   = FLOAT_TO_FIX(0.500);
    fix16_t plane_x = FLOAT_TO_FIX(-0.330);
    fix16_t plane_y = FLOAT_TO_FIX(0.571);

    // ~3 deg rotation step: cos(0.05) = 0.99875, sin(0.05) = 0.04998
    const fix16_t cos_p = FLOAT_TO_FIX(0.99875);
    const fix16_t sin_p = FLOAT_TO_FIX(0.04998);
    const fix16_t move_spd = FLOAT_TO_FIX(0.08);

    while (1) {
        render_frame(pos_x, pos_y, dir_x, dir_y, plane_x, plane_y);

        uint32_t b = BUTTONS;
        if (b & 0x1) { // Turn left
            rotate(&dir_x, &dir_y, &plane_x, &plane_y, cos_p, -sin_p);
        }
        if (b & 0x4) { // Turn right
            rotate(&dir_x, &dir_y, &plane_x, &plane_y, cos_p, sin_p);
        }
        if (b & 0x2) { // Move forward with wall collision
            fix16_t nx = pos_x + fix_mul(dir_x, move_spd);
            fix16_t ny = pos_y + fix_mul(dir_y, move_spd);
            if (world_map[pos_y >> 16][nx >> 16] == 0) pos_x = nx;
            if (world_map[ny >> 16][pos_x >> 16] == 0) pos_y = ny;
        }
    }
    return 0;
}
