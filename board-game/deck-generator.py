import os
from PIL import Image
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
from PyPDF2 import PdfReader, PdfWriter, PageObject

# Configuration
CARD_FOLDER = "cards"
TEMP_PDF = "Gabarito-Padrao.pdf"
OUTPUT_PDF = "deck_with_guides.pdf"
GUIDE_PDF = "Gabarito-Padrao.pdf"

PAGE_WIDTH, PAGE_HEIGHT = A4
CARDS_PER_ROW = 3
CARDS_PER_COL = 3
CARDS_PER_PAGE = CARDS_PER_ROW * CARDS_PER_COL

CARD_WIDTH = 88 * mm  # now width is longer (landscape)
CARD_HEIGHT = 63 * mm
X_MARGIN = (PAGE_WIDTH - (CARDS_PER_ROW * CARD_WIDTH)) / 2
Y_MARGIN = (PAGE_HEIGHT - (CARDS_PER_COL * CARD_HEIGHT)) / 2

def get_card_positions():
    positions = []
    for row in range(CARDS_PER_COL):
        for col in range(CARDS_PER_ROW):
            x = X_MARGIN + col * CARD_WIDTH
            y = PAGE_HEIGHT - Y_MARGIN - (row + 1) * CARD_HEIGHT
            positions.append((x, y))
    return positions

def generate_temp_pdf(card_files):
    c = canvas.Canvas(TEMP_PDF, pagesize=A4)
    positions = get_card_positions()

    for i, card_path in enumerate(card_files):
        pos_index = i % CARDS_PER_PAGE
        x, y = positions[pos_index]

        # Rotate the image
        img = Image.open(card_path).rotate(90, expand=True)
        rotated_path = f"rotated_{i}.png"
        img.save(rotated_path)

        c.drawImage(rotated_path, x, y, width=CARD_WIDTH, height=CARD_HEIGHT)

        os.remove(rotated_path)

        if (i + 1) % CARDS_PER_PAGE == 0:
            c.showPage()

    if len(card_files) % CARDS_PER_PAGE != 0:
        c.showPage()

    c.save()

def merge_with_guide():
    guide_reader = PdfReader(GUIDE_PDF)
    deck_reader = PdfReader(TEMP_PDF)
    writer = PdfWriter()

    for i, page in enumerate(deck_reader.pages):
        bg_page = guide_reader.pages[0] if len(guide_reader.pages) == 1 else guide_reader.pages[i]
        merged = PageObject.create_blank_page(width=PAGE_WIDTH, height=PAGE_HEIGHT)
        merged.merge_page(bg_page)
        merged.merge_page(page)
        writer.add_page(merged)

    with open(OUTPUT_PDF, "wb") as f:
        writer.write(f)

def main():
    card_files = sorted([
        os.path.join(CARD_FOLDER, f) for f in os.listdir(CARD_FOLDER)
        if f.lower().endswith((".png", ".jpg", ".jpeg"))
    ])
    generate_temp_pdf(card_files)
    merge_with_guide()
    print(f"✅ PDF gerado: {OUTPUT_PDF}")

if __name__ == "__main__":
    main()
