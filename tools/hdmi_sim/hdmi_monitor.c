#define SDL_MAIN_HANDLED
#include <SDL.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    int width;
    int height;
    int live_mode;
    int max_frames;
    const char *out_bmp;

    uint32_t *fb;
    SDL_Window *window;
    SDL_Renderer *renderer;
    SDL_Texture *texture;

    int x;
    int y;
    int prev_vde;
    int prev_hsync;
    int prev_vsync;

    int line_total_cnt;
    int line_active_cnt;
    int h_fp_cnt;
    int h_sync_cnt;
    int h_bp_cnt;
    int h_phase;

    int frame_lines_total;
    int frame_lines_active;
    int v_fp_cnt;
    int v_sync_cnt;
    int v_bp_cnt;
    int v_phase;

    int last_h_active;
    int last_h_total;
    int last_h_fp;
    int last_h_sync;
    int last_h_bp;
    int last_v_active;
    int last_v_total;
    int last_v_fp;
    int last_v_sync;
    int last_v_bp;

    int frame_count;
    int synced_to_vsync;
    int non_black_pixels;
    int btn_mask;
    int latch_frames_left[3];
    int quit_requested;
    int initialized;
} MonitorState;

static MonitorState g_mon;

static int write_bmp_24(const char *path, const uint32_t *fb, int w, int h) {
    FILE *f = fopen(path, "wb");
    if (!f) {
        fprintf(stderr, "[hdmi_monitor] Failed to open %s for writing\n", path);
        return -1;
    }

    int row_stride = ((w * 3 + 3) / 4) * 4;
    uint32_t img_size = (uint32_t)(row_stride * h);
    uint32_t file_size = 54 + img_size;

    uint8_t hdr[54];
    memset(hdr, 0, sizeof(hdr));
    hdr[0] = 'B';
    hdr[1] = 'M';
    hdr[2] = (uint8_t)(file_size & 0xFF);
    hdr[3] = (uint8_t)((file_size >> 8) & 0xFF);
    hdr[4] = (uint8_t)((file_size >> 16) & 0xFF);
    hdr[5] = (uint8_t)((file_size >> 24) & 0xFF);
    hdr[10] = 54;
    hdr[14] = 40;
    hdr[18] = (uint8_t)(w & 0xFF);
    hdr[19] = (uint8_t)((w >> 8) & 0xFF);
    hdr[20] = (uint8_t)((w >> 16) & 0xFF);
    hdr[21] = (uint8_t)((w >> 24) & 0xFF);
    hdr[22] = (uint8_t)(h & 0xFF);
    hdr[23] = (uint8_t)((h >> 8) & 0xFF);
    hdr[24] = (uint8_t)((h >> 16) & 0xFF);
    hdr[25] = (uint8_t)((h >> 24) & 0xFF);
    hdr[26] = 1;
    hdr[28] = 24;
    hdr[34] = (uint8_t)(img_size & 0xFF);
    hdr[35] = (uint8_t)((img_size >> 8) & 0xFF);
    hdr[36] = (uint8_t)((img_size >> 16) & 0xFF);
    hdr[37] = (uint8_t)((img_size >> 24) & 0xFF);

    fwrite(hdr, 1, 54, f);

    uint8_t *row = (uint8_t *)calloc((size_t)row_stride, 1);
    if (!row) {
        fclose(f);
        return -1;
    }

    for (int py = h - 1; py >= 0; py--) {
        for (int px = 0; px < w; px++) {
            uint32_t c = fb[py * w + px];
            row[px * 3 + 0] = (uint8_t)(c & 0xFF);
            row[px * 3 + 1] = (uint8_t)((c >> 8) & 0xFF);
            row[px * 3 + 2] = (uint8_t)((c >> 16) & 0xFF);
        }
        fwrite(row, 1, (size_t)row_stride, f);
    }

    free(row);
    fclose(f);
    return 0;
}

static void update_btn_mask(void) {
    const uint8_t *keys = SDL_GetKeyboardState(NULL);
    int mask = 0;
    if (keys[SDL_SCANCODE_UP] || keys[SDL_SCANCODE_W]) mask |= 0x1;
    if (keys[SDL_SCANCODE_DOWN] || keys[SDL_SCANCODE_S]) mask |= 0x2;
    if (keys[SDL_SCANCODE_R] || keys[SDL_SCANCODE_SPACE]) mask |= 0x4;
    for (int i = 0; i < 3; i++) {
        if (g_mon.latch_frames_left[i] > 0) {
            mask |= (1 << i);
        }
    }
    g_mon.btn_mask = mask;
}

static void poll_sdl_events(void) {
    if (!g_mon.live_mode) return;
    SDL_Event ev;
    while (SDL_PollEvent(&ev)) {
        if (ev.type == SDL_QUIT) {
            g_mon.quit_requested = 1;
        } else if (ev.type == SDL_KEYDOWN) {
            SDL_Keycode sym = ev.key.keysym.sym;
            if (sym == SDLK_ESCAPE) {
                g_mon.quit_requested = 1;
            } else if (!ev.key.repeat) {
                if (sym == SDLK_UP || sym == SDLK_w) g_mon.latch_frames_left[0] = 2;
                else if (sym == SDLK_DOWN || sym == SDLK_s) g_mon.latch_frames_left[1] = 2;
                else if (sym == SDLK_r || sym == SDLK_SPACE) g_mon.latch_frames_left[2] = 2;
            }
        }
    }
    update_btn_mask();
}

static void present_live_texture(int in_progress) {
    if (!g_mon.live_mode || !g_mon.texture || !g_mon.renderer) return;

    SDL_UpdateTexture(g_mon.texture, NULL, g_mon.fb, g_mon.width * (int)sizeof(uint32_t));
    SDL_RenderClear(g_mon.renderer);
    SDL_RenderCopy(g_mon.renderer, g_mon.texture, NULL, NULL);
    SDL_RenderPresent(g_mon.renderer);

    char title[160];
    if (in_progress) {
        snprintf(title, sizeof(title),
                 "RISC-V HDMI Monitor | Scanning frame %d (line %d/%d) | Non-black px: %d | Keys: W/Up, S/Down, R/Space",
                 g_mon.frame_count + 1, g_mon.y, g_mon.height, g_mon.non_black_pixels);
    } else {
        snprintf(title, sizeof(title),
                 "RISC-V HDMI Monitor | Frame %d | %dx%d | Non-black px: %d | Keys: W/Up, S/Down, R/Space",
                 g_mon.frame_count, g_mon.last_h_active, g_mon.last_v_active, g_mon.non_black_pixels);
    }
    SDL_SetWindowTitle(g_mon.window, title);
}

static void present_frame(void) {
    if (g_mon.live_mode) {
        present_live_texture(0);
        poll_sdl_events();
    }

    if (g_mon.out_bmp && g_mon.out_bmp[0] != '\0') {
        if (write_bmp_24(g_mon.out_bmp, g_mon.fb, g_mon.width, g_mon.height) == 0) {
            printf("[hdmi_monitor] Saved frame %d to %s\n", g_mon.frame_count, g_mon.out_bmp);
        }
    }
}

int c_hdmi_init(int width, int height) {
    memset(&g_mon, 0, sizeof(g_mon));
    g_mon.width = width;
    g_mon.height = height;

    const char *mode_env = getenv("HDMI_SIM_MODE");
    g_mon.live_mode = (mode_env && strcmp(mode_env, "live") == 0) ? 1 : 0;

    const char *frames_env = getenv("HDMI_SIM_FRAMES");
    if (frames_env && frames_env[0] != '\0') {
        g_mon.max_frames = atoi(frames_env);
    } else {
        g_mon.max_frames = g_mon.live_mode ? 0 : 1;
    }

    g_mon.out_bmp = getenv("HDMI_SIM_OUT");

    g_mon.fb = (uint32_t *)calloc((size_t)(width * height), sizeof(uint32_t));
    if (!g_mon.fb) {
        fprintf(stderr, "[hdmi_monitor] Out of memory allocating %dx%d framebuffer\n", width, height);
        return -1;
    }

    if (g_mon.live_mode) {
        SDL_SetMainReady();
        if (SDL_Init(SDL_INIT_VIDEO) != 0) {
            fprintf(stderr, "[hdmi_monitor] SDL_Init failed: %s\n", SDL_GetError());
            return -1;
        }
        SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");
        g_mon.window = SDL_CreateWindow(
            "RISC-V HDMI Monitor (Waiting for TMDS lock...)",
            SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
            960, 540, SDL_WINDOW_RESIZABLE
        );
        if (!g_mon.window) {
            fprintf(stderr, "[hdmi_monitor] SDL_CreateWindow failed: %s\n", SDL_GetError());
            return -1;
        }
        g_mon.renderer = SDL_CreateRenderer(g_mon.window, -1, SDL_RENDERER_ACCELERATED);
        if (!g_mon.renderer) {
            g_mon.renderer = SDL_CreateRenderer(g_mon.window, -1, SDL_RENDERER_SOFTWARE);
        }
        SDL_RenderSetLogicalSize(g_mon.renderer, width, height);
        g_mon.texture = SDL_CreateTexture(
            g_mon.renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, width, height
        );
        if (!g_mon.texture) {
            fprintf(stderr, "[hdmi_monitor] SDL_CreateTexture failed: %s\n", SDL_GetError());
            return -1;
        }
        present_live_texture(1);
        poll_sdl_events();
    }

    g_mon.initialized = 1;
    printf("[hdmi_monitor] Initialized (%s mode, target %dx%d, max_frames=%d)\n",
           g_mon.live_mode ? "live" : "verify", width, height, g_mon.max_frames);
    fflush(stdout);
    return 0;
}

int c_hdmi_tick(int vde, int hsync, int vsync, int r, int g, int b) {
    if (!g_mon.initialized) return -1;
    if (g_mon.quit_requested) return -1;

    if (vde) {
        if (g_mon.x >= 0 && g_mon.x < g_mon.width && g_mon.y >= 0 && g_mon.y < g_mon.height) {
            uint32_t px = 0xFF000000u | ((uint32_t)(r & 0xFF) << 16) |
                          ((uint32_t)(g & 0xFF) << 8) | (uint32_t)(b & 0xFF);
            g_mon.fb[g_mon.y * g_mon.width + g_mon.x] = px;
            if ((r | g | b) != 0) {
                g_mon.non_black_pixels++;
            }
        }
        g_mon.x++;
        g_mon.line_active_cnt++;
    }

    if (g_mon.prev_vde && !vde) {
        g_mon.h_phase = 1;
        g_mon.h_fp_cnt = 0;
        g_mon.h_sync_cnt = 0;
        g_mon.h_bp_cnt = 0;
    }

    if (!vde) {
        if (g_mon.h_phase == 1) {
            if (hsync) {
                g_mon.h_phase = 2;
                g_mon.h_sync_cnt++;
            } else {
                g_mon.h_fp_cnt++;
            }
        } else if (g_mon.h_phase == 2) {
            if (hsync) {
                g_mon.h_sync_cnt++;
            } else {
                g_mon.h_phase = 3;
                g_mon.h_bp_cnt++;
            }
        } else if (g_mon.h_phase == 3) {
            g_mon.h_bp_cnt++;
        }
    }

    g_mon.line_total_cnt++;

    if (!g_mon.prev_hsync && hsync) {
        if (g_mon.line_active_cnt > 0) {
            g_mon.last_h_active = g_mon.line_active_cnt;
            g_mon.frame_lines_active++;
            g_mon.y++;
            g_mon.v_phase = 1;
            g_mon.v_fp_cnt = 0;
        } else {
            if (g_mon.v_phase == 1) {
                if (vsync) {
                    g_mon.v_phase = 2;
                    g_mon.v_sync_cnt++;
                } else {
                    g_mon.v_fp_cnt++;
                }
            } else if (g_mon.v_phase == 2) {
                if (vsync) {
                    g_mon.v_sync_cnt++;
                } else {
                    g_mon.v_phase = 3;
                    g_mon.v_bp_cnt++;
                }
            } else if (g_mon.v_phase == 3) {
                g_mon.v_bp_cnt++;
            }
        }
        if (g_mon.h_phase >= 2 && g_mon.line_total_cnt > 100) {
            g_mon.last_h_total = g_mon.line_total_cnt;
            g_mon.last_h_fp = g_mon.h_fp_cnt;
        }
        g_mon.line_total_cnt = 0;
        g_mon.line_active_cnt = 0;
        g_mon.x = 0;
        g_mon.frame_lines_total++;

        if (g_mon.live_mode) {
            if ((g_mon.frame_lines_total & 0x1F) == 0) {
                present_live_texture(1);
            }
            if ((g_mon.frame_lines_total & 0x01) == 0) {
                poll_sdl_events();
                if (g_mon.quit_requested) return -1;
            }
        }
    }

    if (g_mon.prev_hsync && !hsync) {
        g_mon.last_h_sync = g_mon.h_sync_cnt;
    }

    if (!g_mon.prev_vde && vde && g_mon.h_phase == 3) {
        g_mon.last_h_bp = g_mon.h_bp_cnt;
        g_mon.h_phase = 0;
    }

    if (!g_mon.prev_vsync && vsync) {
        if (g_mon.live_mode) {
            for (int i = 0; i < 3; i++) {
                if (g_mon.latch_frames_left[i] > 0) g_mon.latch_frames_left[i]--;
            }
            update_btn_mask();
        }
        if (!g_mon.synced_to_vsync) {
            g_mon.synced_to_vsync = 1;
            if (g_mon.live_mode && g_mon.frame_lines_active > 0) {
                present_live_texture(1);
            }
            g_mon.non_black_pixels = 0;
        } else if (g_mon.frame_lines_active > 0) {
            g_mon.frame_count++;
            g_mon.last_v_active = g_mon.frame_lines_active;
            g_mon.last_v_total = g_mon.frame_lines_total;
            g_mon.last_v_fp = g_mon.v_fp_cnt;
            printf("[hdmi_monitor] Frame %d complete: active=%dx%d, non_black=%d\n",
                   g_mon.frame_count, g_mon.last_h_active, g_mon.last_v_active, g_mon.non_black_pixels);
            fflush(stdout);
            present_frame();

            if (g_mon.max_frames > 0 && g_mon.frame_count >= g_mon.max_frames) {
                return -1;
            }
            g_mon.non_black_pixels = 0;
        }
        g_mon.y = 0;
        g_mon.x = 0;
        g_mon.frame_lines_active = 0;
        g_mon.frame_lines_total = 0;
        g_mon.v_phase = 2;
        g_mon.v_sync_cnt = 0;
        g_mon.v_fp_cnt = 0;
        g_mon.v_bp_cnt = 0;
    }

    if (g_mon.prev_vsync && !vsync) {
        g_mon.last_v_sync = g_mon.v_sync_cnt;
    }

    if (!g_mon.prev_vde && vde) {
        if (g_mon.v_phase == 3) {
            g_mon.last_v_bp = g_mon.v_bp_cnt;
        }
    }

    g_mon.prev_vde = vde;
    g_mon.prev_hsync = hsync;
    g_mon.prev_vsync = vsync;

    return g_mon.btn_mask;
}

int c_hdmi_finish(void) {
    if (!g_mon.initialized) return 1;

    printf("\n=== DVI/HDMI TIMING REPORT ===\n");
    printf("Frames decoded : %d\n", g_mon.frame_count);
    printf("Resolution     : %d x %d (expected %d x %d)\n",
           g_mon.last_h_active, g_mon.last_v_active, g_mon.width, g_mon.height);
    printf("Horizontal     : active=%d, fp=%d, sync=%d, bp=%d, total=%d\n",
           g_mon.last_h_active, g_mon.last_h_fp, g_mon.last_h_sync, g_mon.last_h_bp, g_mon.last_h_total);
    printf("Vertical       : active=%d, fp=%d, sync=%d, bp=%d\n",
           g_mon.last_v_active, g_mon.last_v_fp, g_mon.last_v_sync, g_mon.last_v_bp);

    int ok = (g_mon.frame_count >= 1 &&
              g_mon.last_h_active == g_mon.width &&
              g_mon.last_v_active == g_mon.height);
    printf("Status         : %s\n", ok ? "PASS" : "FAIL");
    printf("==============================\n");
    fflush(stdout);

    if (g_mon.texture) SDL_DestroyTexture(g_mon.texture);
    if (g_mon.renderer) SDL_DestroyRenderer(g_mon.renderer);
    if (g_mon.window) SDL_DestroyWindow(g_mon.window);
    if (g_mon.live_mode) SDL_Quit();
    free(g_mon.fb);
    g_mon.initialized = 0;

    return ok ? 0 : 1;
}
