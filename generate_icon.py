#!/usr/bin/env python3
"""Generate app icon for Finanzas iOS app."""

import math
import os
from PIL import Image, ImageDraw, ImageFont

OUTPUT_DIR = "FinanzasIOS/Assets.xcassets/AppIcon.appiconset"
ICON_SIZE = 1024

def create_icon(size=ICON_SIZE):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background: rounded rectangle with gradient-like effect
    bg_color = (31, 41, 55)  # Dark blue-gray
    margin = size // 16
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=size // 4,
        fill=bg_color
    )

    # Inner glow circle
    center = size // 2
    glow_radius = size // 3
    for r in range(glow_radius, glow_radius // 2, -10):
        alpha = int(20 * (1 - (r - glow_radius // 2) / (glow_radius // 2)))
        draw.ellipse(
            [center - r, center - r, center + r, center + r],
            fill=(99, 102, 241, alpha)  # Indigo glow
        )

    # Draw a stylized chart/graph (bars going up)
    bar_width = size // 14
    spacing = size // 16
    base_y = int(size * 0.72)
    bar_heights = [
        int(size * 0.18),
        int(size * 0.32),
        int(size * 0.26),
        int(size * 0.40),
        int(size * 0.22),
        int(size * 0.35),
    ]
    bar_colors = [
        (129, 199, 132),  # Green
        (129, 199, 132),
        (229, 115, 115),  # Red
        (129, 199, 132),
        (229, 115, 115),
        (129, 199, 132),
    ]

    total_width = len(bar_heights) * (bar_width + spacing) - spacing
    start_x = center - total_width // 2

    for i, (height, color) in enumerate(zip(bar_heights, bar_colors)):
        x0 = start_x + i * (bar_width + spacing)
        y0 = base_y - height
        x1 = x0 + bar_width
        y1 = base_y
        draw.rounded_rectangle([x0, y0, x1, y1], radius=bar_width // 4, fill=color)

    # Arrow line going up through bars
    line_x = start_x + total_width // 2
    arrow_start_y = int(size * 0.62)
    arrow_end_y = int(size * 0.28)
    arrow_color = (255, 255, 255, 230)
    draw.line(
        [(line_x, arrow_start_y), (line_x, arrow_end_y)],
        fill=arrow_color,
        width=size // 40
    )
    # Arrow head
    arrow_head = size // 16
    draw.polygon(
        [
            (line_x, arrow_end_y - arrow_head // 2),
            (line_x - arrow_head // 2, arrow_end_y + arrow_head // 3),
            (line_x + arrow_head // 2, arrow_end_y + arrow_head // 3),
        ],
        fill=arrow_color
    )

    # Small dollar sign at the top of arrow
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size // 12)
    except (OSError, IOError):
        font = ImageFont.load_default()
    dollar_text = "$"
    bbox = draw.textbbox((0, 0), dollar_text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    text_x = line_x - text_w // 2
    text_y = arrow_end_y - arrow_head - text_h - size // 40
    draw.text((text_x, text_y), dollar_text, fill=(255, 255, 255, 255), font=font)

    # Save the 1024x1024 icon
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_path = os.path.join(OUTPUT_DIR, "icon-1024.png")
    img.save(output_path, "PNG")
    print(f"Icon saved to: {output_path}")
    return output_path

if __name__ == "__main__":
    create_icon()
