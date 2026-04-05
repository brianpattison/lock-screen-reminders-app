#!/usr/bin/env python3
"""Generate a 1024x1024 app icon for Reminders Widget."""

from PIL import Image, ImageDraw, ImageFont
import math
import os

SIZE = 1024
CORNER_RADIUS = 224  # iOS icon corner radius at 1024px


def rounded_rectangle_mask(size, radius):
    """Create a mask for rounded rectangle."""
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (size - 1, size - 1)], radius=radius, fill=255)
    return mask


def draw_gradient(draw, size):
    """Draw a blue-to-teal gradient background."""
    for y in range(size):
        ratio = y / size
        r = int(0 + (0 - 0) * ratio)
        g = int(122 + (180 - 122) * ratio)
        b = int(255 + (220 - 255) * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b))


def draw_circle(draw, cx, cy, radius, outline_color, outline_width):
    """Draw an outlined circle."""
    bbox = [cx - radius, cy - radius, cx + radius, cy + radius]
    draw.ellipse(bbox, outline=outline_color, width=outline_width)


def draw_line_shape(draw, x, y, width, height, fill, radius=None):
    """Draw a rounded rectangle as a text line placeholder."""
    if radius is None:
        radius = height // 2
    draw.rounded_rectangle(
        [(x, y), (x + width, y + height)], radius=radius, fill=fill
    )


def main():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Draw gradient background
    draw_gradient(draw, SIZE)

    # Semi-transparent white overlay for depth
    overlay = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    # Subtle radial highlight at top-left
    for i in range(400, 0, -1):
        alpha = int(15 * (1 - i / 400))
        overlay_draw.ellipse(
            [200 - i, 100 - i, 200 + i, 100 + i], fill=(255, 255, 255, alpha)
        )
    img = Image.alpha_composite(img, overlay)
    draw = ImageDraw.Draw(img)

    # Widget parameters
    white = (255, 255, 255, 255)
    white_semi = (255, 255, 255, 200)
    circle_radius = 28
    line_height = 20
    circle_stroke = 7
    spacing = 120
    start_y = 392
    left_margin = 280
    line_x = left_margin + circle_radius * 2 + 40

    # Draw 3 reminder rows
    for i in range(3):
        cy = start_y + i * spacing

        # Circle indicator
        draw_circle(draw, left_margin, cy, circle_radius, white, circle_stroke)

        # Text line (rounded rectangle)
        line_widths = [380, 300, 340]
        draw_line_shape(
            draw, line_x, cy - line_height // 2, line_widths[i], line_height, white_semi
        )

    # Apply rounded rectangle mask
    mask = rounded_rectangle_mask(SIZE, CORNER_RADIUS)

    # Create final image with rounded corners
    final = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    final.paste(img, mask=mask)

    # Save
    output_dir = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "Assets.xcassets",
        "AppIcon.appiconset",
    )
    output_path = os.path.join(output_dir, "AppIcon.png")

    # Convert to RGB for PNG (App Store requires no alpha in final icon)
    # But first save with alpha for the rounded corners
    # Actually, App Store icons should be square with NO transparency
    # iOS applies the rounding automatically
    square_img = Image.new("RGB", (SIZE, SIZE))
    square_img.paste(img, (0, 0))
    square_img.save(output_path, "PNG")
    print(f"Icon saved to {output_path}")


if __name__ == "__main__":
    main()
