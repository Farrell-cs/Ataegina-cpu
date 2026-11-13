#include <stdint.h>

#define VRAM       ((volatile uint8_t*)0x80000000)
#define BUTTONS    (*(volatile uint32_t*)0x80010000)

#define SCREEN_W   160
#define SCREEN_H   90

#define COLOR_BLACK 0x00
#define COLOR_WHITE 0xFF
#define COLOR_GREEN 0x1C
#define COLOR_RED   0xE0

typedef struct {
    int x, y;
    int w, h;
    int dx, dy;
} ball_t;

typedef struct {
    int x, y;
    int w, h;
} paddle_t;

static ball_t ball;
static paddle_t paddle[2];
static int score[2] = {0, 0};

void draw_rect(int x, int y, int w, int h, uint8_t color) {
    for (int j = y; j < y + h; j++) {
        if (j < 0 || j >= SCREEN_H) continue;
        int row_offset = j * SCREEN_W;
        for (int i = x; i < x + w; i++) {
            if (i < 0 || i >= SCREEN_W) continue;
            VRAM[row_offset + i] = color;
        }
    }
}

void clear_screen(uint8_t color) {
    for (int i = 0; i < SCREEN_W * SCREEN_H; i++) {
        VRAM[i] = color;
    }
}

void delay(volatile int count) {
    while (count > 0) {
        count--;
    }
}

static void draw_net(void) {
    for (int y = 4; y < SCREEN_H; y += 8) {
        draw_rect(SCREEN_W / 2 - 1, y, 2, 4, 0x49);
    }
}

static void draw_scores(void) {
    for (int i = 0; i < score[0] && i < 10; i++) draw_rect(25 + (i * 4), 4, 2, 4, COLOR_WHITE);
    for (int i = 0; i < score[1] && i < 10; i++) draw_rect(SCREEN_W - 25 - (i * 4), 4, 2, 4, COLOR_WHITE);
}

static void init_game(void) {
    ball.w  = 3;
    ball.h  = 3;
    ball.x  = (SCREEN_W / 2) - 1;
    ball.y  = (SCREEN_H / 2) - 1;
    ball.dx = 1;
    ball.dy = 1;

    paddle[0].x = 8;
    paddle[0].y = (SCREEN_H / 2) - 10;
    paddle[0].w = 3;
    paddle[0].h = 20;

    paddle[1].x = SCREEN_W - 11;
    paddle[1].y = (SCREEN_H / 2) - 10;
    paddle[1].w = 3;
    paddle[1].h = 20;

    clear_screen(COLOR_BLACK);
    draw_net();
    draw_scores();
}

int check_collision(ball_t a, paddle_t b) {
    if (a.x > b.x + b.w) return 0;
    if (a.x + a.w < b.x) return 0;
    if (a.y > b.y + b.h) return 0;
    if (a.y + a.h < b.y) return 0;
    return 1;
}

static void move_ball(void) {
    ball.x += ball.dx;
    ball.y += ball.dy;

    if (ball.y <= 0 || ball.y >= SCREEN_H - ball.h) {
        ball.dy = -ball.dy;
    }

    if (ball.x < 0) {
        score[1]++;
        init_game();
        return;
    }

    if (ball.x > SCREEN_W - ball.w) {
        score[0]++;
        init_game();
        return;
    }

    for (int i = 0; i < 2; i++) {
        if (check_collision(ball, paddle[i])) {
            ball.dx = -ball.dx;
            int hit_pos = (paddle[i].y + paddle[i].h) - ball.y;
            if (hit_pos < 7)       ball.dy = 2;
            else if (hit_pos > 14) ball.dy = -2;
            else                   ball.dy = (ball.dy >= 0) ? 1 : -1;

            if (ball.dx > 0 && ball.x < 12)                 ball.x = 12;
            else if (ball.dx < 0 && ball.x > SCREEN_W - 15) ball.x = SCREEN_W - 15;
        }
    }
}

static void move_paddle_ai(void) {
    int center = paddle[0].y + (paddle[0].h / 2);
    if (ball.dx < 0) {
        if (ball.y > center && paddle[0].y < SCREEN_H - paddle[0].h) paddle[0].y += 1;
        else if (ball.y < center && paddle[0].y > 0)                 paddle[0].y -= 1;
    }
}

static void move_paddle(int dir) {
    if (dir == 0 && paddle[1].y < SCREEN_H - paddle[1].h) paddle[1].y += 2;
    if (dir == 1 && paddle[1].y > 0)                      paddle[1].y -= 2;
}

int main(void) {
    init_game();

    int old_ball_x = ball.x;
    int old_ball_y = ball.y;
    int old_p0_y   = paddle[0].y;
    int old_p1_y   = paddle[1].y;

    while (1) {
        uint32_t btn = BUTTONS;
        if (btn & 0x04) {
            score[0] = 0;
            score[1] = 0;
            init_game();
            old_ball_x = ball.x;
            old_ball_y = ball.y;
            old_p0_y   = paddle[0].y;
            old_p1_y   = paddle[1].y;
            continue;
        }
        if (btn & 0x01) move_paddle(1);
        if (btn & 0x02) move_paddle(0);

        move_paddle_ai();
        move_ball();

        // Flicker-free partial erase: only wipe old positions
        draw_rect(old_p0_y != paddle[0].y ? paddle[0].x : 0, old_p0_y, paddle[0].w, paddle[0].h, COLOR_BLACK);
        draw_rect(old_p1_y != paddle[1].y ? paddle[1].x : 0, old_p1_y, paddle[1].w, paddle[1].h, COLOR_BLACK);
        draw_rect(old_ball_x, old_ball_y, ball.w, ball.h, COLOR_BLACK);

        // Re-draw net segment if ball passed through center
        if (old_ball_x >= (SCREEN_W / 2 - 4) && old_ball_x <= (SCREEN_W / 2 + 4)) {
            draw_net();
        }

        // Draw elements at new positions
        draw_rect(paddle[0].x, paddle[0].y, paddle[0].w, paddle[0].h, COLOR_GREEN);
        draw_rect(paddle[1].x, paddle[1].y, paddle[1].w, paddle[1].h, COLOR_RED);
        draw_rect(ball.x, ball.y, ball.w, ball.h, COLOR_WHITE);

        old_ball_x = ball.x;
        old_ball_y = ball.y;
        old_p0_y   = paddle[0].y;
        old_p1_y   = paddle[1].y;

#ifdef SIM_FAST
        delay(1200);
#else
        // Smooth ~60 FPS delay at 36.875 MHz
        delay(40000);
#endif
    }

    return 0;
}
