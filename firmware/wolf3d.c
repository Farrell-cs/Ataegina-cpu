#pragma GCC optimize("Os")
#include <stdint.h>

#define VRAM     ((volatile uint8_t*)0x80000000)
#define BUTTONS  (*(volatile uint32_t*)0x80010000)

#define SCREEN_W 320
#define SCREEN_H 180
#define MAP_W    8
#define MAP_H    8
#define TEX_SZ   16
#define NUM_SPR  3

typedef int32_t fix16_t;

#define ONE             ((fix16_t)(1 << 16))
#define FLOAT_TO_FIX(x) ((fix16_t)((x) * 65536.0))

static inline fix16_t fix_mul(fix16_t a, fix16_t b) {
    return (fix16_t)(((int64_t)a * (int64_t)b) >> 16);
}

static inline fix16_t fix_inv_abs(fix16_t x) {
    fix16_t ax = (x < 0) ? -x : x;
    if (ax < 256) return 0x10000000;
    return ((int32_t)(1 << 24) / ax) << 8;
}

static uint8_t world_map[MAP_H][MAP_W] = {
    {1, 1, 1, 1, 1, 1, 1, 1},
    {1, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 2, 0, 0, 3, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 1},
    {1, 0, 0, 4, 0, 0, 0, 1},
    {1, 0, 3, 0, 0, 2, 0, 1},
    {1, 0, 0, 0, 0, 0, 0, 1},
    {1, 1, 1, 1, 1, 1, 1, 1}
};

typedef struct {
    fix16_t x, y;
    uint8_t alive;
    uint8_t hit_timer;
} sprite_t;

static sprite_t sprites[NUM_SPR] = {
    {FLOAT_TO_FIX(3.5), FLOAT_TO_FIX(2.5), 1, 0},
    {FLOAT_TO_FIX(5.5), FLOAT_TO_FIX(4.5), 1, 0},
    {FLOAT_TO_FIX(2.5), FLOAT_TO_FIX(6.2), 1, 0}
};

static fix16_t z_buf[SCREEN_W];
static uint8_t tex[4][TEX_SZ * TEX_SZ];

__attribute__((noinline)) static void init_textures(void) {
    for (int y = 0; y < TEX_SZ; y++) {
        for (int x = 0; x < TEX_SZ; x++) {
            int idx = y * TEX_SZ + x;
            // Tex 0: Wolf3D grey/red stone brick
            int mortar = ((y & 3) == 0) || (((x + ((y >> 2) & 1) * 4) & 7) == 0);
            tex[0][idx] = mortar ? 0x49 : (((x ^ y) & 1) ? 0x92 : 0xB6);

            // Tex 1: Blue tech/eagle wall with trim
            int border = (x == 0 || x == 15 || y == 0 || y == 15);
            int cross  = (x == 7 || x == 8 || y == 7 || y == 8);
            tex[1][idx] = border ? 0x1F : (cross ? 0xFF : 0x0B);

            // Tex 2: Wood / mossy crate
            int diag = (x == y || x + y == 15);
            tex[2][idx] = (border || diag) ? 0x64 : 0xA8;

            // Tex 3: Gold / eagle banner wall
            tex[3][idx] = (y >= 4 && y <= 11 && x >= 4 && x <= 11) ? 0xE0 : (border ? 0x90 : 0xFC);
        }
    }
}

static inline uint8_t darken_rgb332(uint8_t c) {
    // Halve R(7..5), G(4..2), B(1..0) for Wolf3D X/Y side shading
    uint8_t r = (c >> 6) & 0x03;
    uint8_t g = (c >> 3) & 0x03;
    uint8_t b = (c >> 1) & 0x01;
    return (uint8_t)((r << 5) | (g << 2) | b);
}

static void render_walls(fix16_t pos_x, fix16_t pos_y,
                         fix16_t dir_x, fix16_t dir_y,
                         fix16_t plane_x, fix16_t plane_y) {
    for (int x = 0; x < SCREEN_W; x++) {
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
        if (perp_dist < 4096) perp_dist = 4096;
        z_buf[x] = perp_dist;

        int line_h = (int)((SCREEN_H << 16) / perp_dist);
        if (line_h < 1) line_h = 1;
        int draw_start = (SCREEN_H - line_h) >> 1;
        int draw_end   = (SCREEN_H + line_h) >> 1;

        fix16_t wall_x = (side == 0) ? (pos_y + fix_mul(perp_dist, ray_dy))
                                     : (pos_x + fix_mul(perp_dist, ray_dx));
        int tex_x = (wall_x >> 12) & (TEX_SZ - 1);
        int tex_id = (hit > 0 && hit <= 4) ? (hit - 1) : 0;

        fix16_t step_t = (TEX_SZ << 16) / line_h;
        fix16_t tex_pos = 0;
        if (draw_start < 0) {
            tex_pos = (-draw_start) * step_t;
            draw_start = 0;
        }
        if (draw_end >= SCREEN_H) draw_end = SCREEN_H - 1;

        for (int y = 0; y < SCREEN_H; y++) {
            uint8_t px;
            if (y < draw_start) {
                px = 0x24; // Dark Wolf3D ceiling
            } else if (y <= draw_end) {
                int tex_y = (tex_pos >> 16) & (TEX_SZ - 1);
                tex_pos += step_t;
                px = tex[tex_id][tex_y * TEX_SZ + tex_x];
                if (side) px = darken_rgb332(px);
            } else {
                px = 0x49; // Dark Wolf3D floor
            }
            VRAM[y * SCREEN_W + x] = px;
        }
    }
}

__attribute__((noinline)) static void render_sprites(fix16_t pos_x, fix16_t pos_y,
                           fix16_t dir_x, fix16_t dir_y,
                           fix16_t plane_x, fix16_t plane_y) {
    fix16_t det = fix_mul(plane_x, dir_y) - fix_mul(dir_x, plane_y);
    if (det > -256 && det < 256) return;
    fix16_t inv_det = (det < 0) ? -fix_inv_abs(det) : fix_inv_abs(det);

    for (int i = 0; i < NUM_SPR; i++) {
        if (!sprites[i].alive) continue;
        fix16_t sx = sprites[i].x - pos_x;
        fix16_t sy = sprites[i].y - pos_y;

        fix16_t num_x = fix_mul(dir_y, sx) - fix_mul(dir_x, sy);
        fix16_t num_y = fix_mul(plane_x, sy) - fix_mul(plane_y, sx);
        fix16_t tx = fix_mul(num_x, inv_det);
        fix16_t ty = fix_mul(num_y, inv_det);
        if (ty <= 8192) continue;

        int scr_x = (SCREEN_W >> 1) + (int)((((int32_t)(SCREEN_W >> 1) * (tx >> 4)) / (ty >> 4)));
        int spr_h = (int)((SCREEN_H << 16) / ty);
        if (spr_h < 2 || spr_h > SCREEN_H * 2) continue;

        int y0 = (SCREEN_H - spr_h) >> 1;
        int y1 = (SCREEN_H + spr_h) >> 1;
        int x0 = scr_x - (spr_h >> 1);
        int x1 = scr_x + (spr_h >> 1);

        int ys = (y0 < 0) ? 0 : y0;
        int ye = (y1 >= SCREEN_H) ? (SCREEN_H - 1) : y1;
        int xs = (x0 < 0) ? 0 : x0;
        int xe = (x1 >= SCREEN_W) ? (SCREEN_W - 1) : x1;

        for (int stripe = xs; stripe <= xe; stripe++) {
            if (ty >= z_buf[stripe]) continue;
            int u = ((stripe - x0) * 16) / spr_h;
            for (int y = ys; y <= ye; y++) {
                int v = ((y - y0) * 16) / spr_h;
                // Procedural Guard / Enemy silhouette
                uint8_t col = 0;
                if (v >= 1 && v <= 4 && u >= 6 && u <= 9) {
                    col = (v == 1) ? 0x6D : 0xFA; // Helmet & face
                } else if (v >= 5 && v <= 10 && u >= 4 && u <= 11) {
                    col = (sprites[i].hit_timer > 0) ? 0xE0 : ((u == 7 || u == 8) ? 0xFF : 0x18); // Uniform
                } else if (v >= 11 && v <= 15 && ((u >= 5 && u <= 6) || (u >= 9 && u <= 10))) {
                    col = 0x49; // Boots/legs
                }
                if (col != 0) {
                    VRAM[y * SCREEN_W + stripe] = col;
                }
            }
        }
        if (sprites[i].hit_timer > 0) sprites[i].hit_timer--;
    }
}

__attribute__((noinline)) static void render_weapon_hud(int muzzle_flash) {
    // Simple first-person pistol at bottom-center + crosshair
    int cx = SCREEN_W >> 1;
    int cy = SCREEN_H >> 1;
    VRAM[cy * SCREEN_W + cx] = 0xFF;

    for (int y = SCREEN_H - 36; y < SCREEN_H; y++) {
        for (int x = cx - 10; x <= cx + 10; x++) {
            uint8_t col = 0;
            if (muzzle_flash && y < SCREEN_H - 22 && x >= cx - 6 && x <= cx + 6) {
                col = ((x + y) & 1) ? 0xFC : 0xE0; // Muzzle flash
            } else if (y >= SCREEN_H - 24 && x >= cx - 4 && x <= cx + 4) {
                col = (x >= cx - 2 && x <= cx + 2) ? 0x92 : 0x49; // Gun barrel
            } else if (y >= SCREEN_H - 12 && x >= cx - 6 && x <= cx + 6) {
                col = 0x64; // Grip
            }
            if (col != 0) VRAM[y * SCREEN_W + x] = col;
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
    init_textures();

    fix16_t pos_x   = FLOAT_TO_FIX(1.5);
    fix16_t pos_y   = FLOAT_TO_FIX(1.5);
    fix16_t dir_x   = FLOAT_TO_FIX(0.866);
    fix16_t dir_y   = FLOAT_TO_FIX(0.500);
    fix16_t plane_x = FLOAT_TO_FIX(-0.330);
    fix16_t plane_y = FLOAT_TO_FIX(0.571);

    const fix16_t cos_p = FLOAT_TO_FIX(0.99875);
    const fix16_t sin_p = FLOAT_TO_FIX(0.04998);
    const fix16_t move_spd = FLOAT_TO_FIX(0.08);
    int flash = 0;

    while (1) {
        render_walls(pos_x, pos_y, dir_x, dir_y, plane_x, plane_y);
        render_sprites(pos_x, pos_y, dir_x, dir_y, plane_x, plane_y);
        render_weapon_hud(flash);
        if (flash > 0) flash--;

        uint32_t b = BUTTONS & 0x7;
        if (b == 0x5) { // BTN0 + BTN2 together = Shoot!
            flash = 2;
            for (int i = 0; i < NUM_SPR; i++) {
                if (!sprites[i].alive) continue;
                fix16_t sx = sprites[i].x - pos_x;
                fix16_t sy = sprites[i].y - pos_y;
                fix16_t fwd = fix_mul(sx, dir_x) + fix_mul(sy, dir_y);
                fix16_t lat = fix_mul(sx, -dir_y) + fix_mul(sy, dir_x);
                if (fwd > 0 && fwd < z_buf[SCREEN_W >> 1] && lat > -20000 && lat < 20000) {
                    sprites[i].alive = 0;
                }
            }
        } else {
            if (b & 0x1) rotate(&dir_x, &dir_y, &plane_x, &plane_y, cos_p, -sin_p);
            if (b & 0x4) rotate(&dir_x, &dir_y, &plane_x, &plane_y, cos_p, sin_p);
            if (b & 0x2) {
                fix16_t nx = pos_x + fix_mul(dir_x, move_spd);
                fix16_t ny = pos_y + fix_mul(dir_y, move_spd);
                if (world_map[pos_y >> 16][nx >> 16] == 0) pos_x = nx;
                if (world_map[ny >> 16][pos_x >> 16] == 0) pos_y = ny;
            }
        }

        // Frame-rate cap (~30 FPS on 36.875 MHz hardware)
        for (volatile int d = 0; d < 80000; d++) {}
    }
    return 0;
}
