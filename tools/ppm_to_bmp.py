import sys
import struct

def ppm_to_bmp(ppm_path, bmp_path):
    with open(ppm_path, "r") as f:
        header = f.readline().strip()
        dims = f.readline().strip()
        while dims.startswith("#"):
            dims = f.readline().strip()
        width, height = map(int, dims.split())
        max_val = int(f.readline().strip())
        pixel_data = list(map(int, f.read().split()))

    # BMP row must be padded to multiple of 4 bytes
    row_stride = (width * 3 + 3) & ~3
    image_size = row_stride * height
    file_size = 54 + image_size

    with open(bmp_path, "wb") as f:
        # BMP Header
        f.write(b'BM')
        f.write(struct.pack('<IHHI', file_size, 0, 0, 54))
        # DIB Header (BITMAPINFOHEADER)
        f.write(struct.pack('<IIIHHIIIIII', 40, width, height, 1, 24, 0, image_size, 2835, 2835, 0, 0))

        # Pixel data (bottom-to-top, BGR order)
        for y in range(height - 1, -1, -1):
            row = bytearray()
            for x in range(width):
                idx = (y * width + x) * 3
                r = pixel_data[idx]
                g = pixel_data[idx + 1]
                b = pixel_data[idx + 2]
                row.extend([b, g, r])
            while len(row) % 4 != 0:
                row.append(0)
            f.write(row)

    print(f"-> Generated standard Windows bitmap: {bmp_path} ({width}x{height})")

if __name__ == "__main__":
    ppm = sys.argv[1] if len(sys.argv) > 1 else "pong_frame.ppm"
    bmp = sys.argv[2] if len(sys.argv) > 2 else "pong_frame.bmp"
    ppm_to_bmp(ppm, bmp)
