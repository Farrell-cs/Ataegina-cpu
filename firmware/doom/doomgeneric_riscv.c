#include "doomgeneric.h"
#include "doomkeys.h"
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>
#include <errno.h>

#define VRAM      ((volatile uint8_t*)0x80000000)
#define BUTTONS   (*(volatile uint32_t*)0x80010000)
#define TIMER_MS  (*(volatile uint32_t*)0x80010004)
#define WAD_BASE  ((const uint8_t*)0x11000000)

#define SCREEN_W  320
#define SCREEN_H  180

/* --- Bare-metal newlib syscalls (DDR3 Heap + In-Memory WAD at 0x11000000) --- */
extern char _end;
static char *heap_ptr = &_end;

void *_sbrk(int incr) {
    char *prev = heap_ptr;
    heap_ptr += incr;
    return (void *)prev;
}

static uint32_t wad_size = 0;
static uint32_t wad_pos  = 0;
static int      wad_open = 0;

static uint32_t detect_wad_size(void) {
    /* WAD header: 4-byte magic ("IWAD"), uint32 numlumps, uint32 infotableofs */
    if (WAD_BASE[0] == 'I' && WAD_BASE[1] == 'W' && WAD_BASE[2] == 'A' && WAD_BASE[3] == 'D') {
        uint32_t numlumps = *(const uint32_t *)(WAD_BASE + 4);
        uint32_t dir_ofs  = *(const uint32_t *)(WAD_BASE + 8);
        return dir_ofs + numlumps * 16U;
    }
    return 0;
}

int _open(const char *name, int flags, int mode) {
    (void)flags; (void)mode;
    if (strstr(name, ".wad") || strstr(name, ".WAD")) {
        wad_size = detect_wad_size();
        if (wad_size == 0) {
            errno = ENOENT;
            return -1;
        }
        wad_pos  = 0;
        wad_open = 1;
        return 3;
    }
    errno = ENOENT;
    return -1;
}

int _close(int fd) {
    if (fd == 3) wad_open = 0;
    return 0;
}

int _read(int fd, char *buf, int len) {
    if (fd == 3 && wad_open) {
        if (wad_pos >= wad_size) return 0;
        uint32_t avail = wad_size - wad_pos;
        uint32_t n = ((uint32_t)len < avail) ? (uint32_t)len : avail;
        memcpy(buf, WAD_BASE + wad_pos, n);
        wad_pos += n;
        return (int)n;
    }
    return 0;
}

int _lseek(int fd, int offset, int whence) {
    if (fd == 3 && wad_open) {
        int32_t next = (int32_t)wad_pos;
        if (whence == 0) next = offset;
        else if (whence == 1) next = (int32_t)wad_pos + offset;
        else if (whence == 2) next = (int32_t)wad_size + offset;
        if (next < 0) next = 0;
        if ((uint32_t)next > wad_size) next = (int32_t)wad_size;
        wad_pos = (uint32_t)next;
        return (int)wad_pos;
    }
    return -1;
}

int _fstat(int fd, struct stat *st) {
    memset(st, 0, sizeof(*st));
    if (fd == 3 && wad_open) {
        st->st_mode = S_IFREG;
        st->st_size = (off_t)wad_size;
    } else {
        st->st_mode = S_IFCHR;
    }
    return 0;
}

int _isatty(int fd) { return (fd <= 2) ? 1 : 0; }
int _write(int fd, char *buf, int len) { (void)fd; (void)buf; return len; }
void _exit(int status) { (void)status; while (1) {} }
int _kill(int pid, int sig) { (void)pid; (void)sig; errno = EINVAL; return -1; }
int _getpid(void) { return 1; }
int mkdir(const char *path, mode_t mode) { (void)path; (void)mode; return 0; }

/* --- doomgeneric 5 hardware hooks --- */
void DG_Init(void) {
    for (int i = 0; i < SCREEN_W * SCREEN_H; i++) {
        VRAM[i] = 0x00;
    }
}

void DG_DrawFrame(void) {
    /* Downscale 320x200 ARGB8888 -> 320x180 RGB332 VRAM */
    for (int y = 0; y < SCREEN_H; y++) {
        int src_y = (y * DOOMGENERIC_RESY) / SCREEN_H;
        const uint32_t *src_row = (const uint32_t *)(DG_ScreenBuffer + src_y * DOOMGENERIC_RESX);
        volatile uint8_t *dst_row = VRAM + y * SCREEN_W;
        for (int x = 0; x < SCREEN_W; x++) {
            uint32_t p = src_row[x];
            uint8_t r = (uint8_t)((p >> 21) & 0x07);
            uint8_t g = (uint8_t)((p >> 13) & 0x07);
            uint8_t b = (uint8_t)((p >> 6)  & 0x03);
            dst_row[x] = (uint8_t)((r << 5) | (g << 2) | b);
        }
    }
}

void DG_SleepMs(uint32_t ms) {
    uint32_t start = TIMER_MS;
    while ((TIMER_MS - start) < ms) {}
}

uint32_t DG_GetTicksMs(void) {
    return TIMER_MS;
}

static uint32_t prev_btn = 0;
static int key_q_head = 0, key_q_tail = 0;
static uint16_t key_q[16];

static void push_key(int pressed, unsigned char k) {
    key_q[key_q_head] = (uint16_t)((pressed << 8) | k);
    key_q_head = (key_q_head + 1) & 15;
}

int DG_GetKey(int *pressed, unsigned char *key) {
    uint32_t cur = BUTTONS & 0x7;
    if (cur != prev_btn) {
        uint32_t diff = cur ^ prev_btn;
        if (cur == 0x5) {
            push_key(1, KEY_FIRE);
            push_key(1, KEY_ENTER);
        } else if (prev_btn == 0x5) {
            push_key(0, KEY_FIRE);
            push_key(0, KEY_ENTER);
        } else {
            if (diff & 0x1) push_key((cur & 0x1) != 0, KEY_LEFTARROW);
            if (diff & 0x2) push_key((cur & 0x2) != 0, KEY_UPARROW);
            if (diff & 0x4) push_key((cur & 0x4) != 0, KEY_RIGHTARROW);
        }
        prev_btn = cur;
    }

    if (key_q_tail == key_q_head) return 0;
    uint16_t ev = key_q[key_q_tail];
    key_q_tail = (key_q_tail + 1) & 15;
    *pressed = (ev >> 8) & 1;
    *key     = (unsigned char)(ev & 0xFF);
    return 1;
}

void DG_SetWindowTitle(const char *title) { (void)title; }

int main(void) {
    char *argv[] = { "doom", "-iwad", "doom1.wad", "-warp", "1", "1", NULL };
    doomgeneric_Create(6, argv);
    while (1) {
        doomgeneric_Tick();
    }
    return 0;
}
