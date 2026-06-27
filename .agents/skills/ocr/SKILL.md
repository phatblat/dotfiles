---
name: ocr
description: OCR scanned PDFs and image files into searchable text using pdftoppm + tesseract (or ocrmypdf if available). Load when about to OCR a scanned PDF or image, or when extracted PDF text is empty/garbled.
---

# OCR Skill

Convert scanned PDFs (no embedded text) or image files into searchable plain text or searchable PDFs. Default pipeline is `pdftoppm` → `tesseract`, optionally replaced by `ocrmypdf` when installed.

## When to load

- Reading a PDF and `pypdf`/`pdftotext`/Read returns empty or garbled text → it's a scan, OCR it.
- About to summarize a textbook/manual/legal doc supplied as an image-based PDF.
- Need a searchable PDF (text layer) for later grepping or text extraction.
- OCR'ing standalone images (JPEG, PNG, TIFF) into text.

## Quick Patterns

| Task                           | Command                                                        |
| ------------------------------ | -------------------------------------------------------------- |
| Check if PDF has embedded text | `pdftotext input.pdf - \| wc -c` (≈0 = scan)                   |
| Render PDF → 300 DPI PNGs      | `pdftoppm -r 300 input.pdf out -png`                           |
| OCR one image → text file      | `tesseract page.png page --psm 1`                              |
| OCR one image → stdout         | `tesseract page.png - --psm 1`                                 |
| Searchable PDF (one page)      | `tesseract page.png page --psm 1 pdf`                          |
| Best DIY: parallel PDF OCR     | see [Recipe: Parallel PDF OCR](#recipe-parallel-pdf-ocr) below |
| Best overall (if installed)    | `ocrmypdf in.pdf out.pdf` (adds text layer in-place)           |
| Install on macOS               | `brew install tesseract poppler ocrmypdf`                      |

## Tool selection

```
have ocrmypdf? ──yes──► ocrmypdf in.pdf out.pdf
                                 │
                                 └─ also want plain text? `pdftotext out.pdf out.txt`
       │
       no
       │
       ▼
Need just text? ──► pdftoppm + tesseract (Recipe below)
Need searchable PDF without ocrmypdf? ──► render → tesseract `pdf` config → pdfunite
```

Prefer `ocrmypdf` when installed: it handles deskewing, rotation, language detection, optimization, and produces a real searchable PDF in one call. Falls back to DIY when not available.

## Key knobs

| Knob                          | Default         | Why                                                                                                                                                                                                                                       |
| ----------------------------- | --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **DPI** (`pdftoppm -r`)       | **300**         | 200 loses accuracy on small/serif text; 600 doubles file size and time with marginal gain. Drop to 200 only for clean modern laser-printed pages.                                                                                         |
| **PSM** (`tesseract --psm N`) | **1**           | Auto page segmentation with OSD (orientation + script detection). Handles single-column body text, two-column books, headers, page numbers. Use `6` for "uniform block" if you know layout is plain; `4` for single-column variable size. |
| **Language** (`-l <lang>`)    | `eng` (default) | Use `-l eng+fra` for mixed-language docs. `tesseract --list-langs` to see installed. Install more via `brew install tesseract-lang`.                                                                                                      |
| **OEM** (`--oem 1`)           | LSTM only       | Default LSTM neural engine. Rarely needs changing.                                                                                                                                                                                        |

## Recipe: Parallel PDF OCR

For multi-page scans, parallelize OCR — each page is independent. Cuts a 82-page book OCR from ~8 min serial to ~1–2 min on a modern Mac.

```bash
#!/usr/bin/env bash
# ocr-pdf.sh — OCR a scanned PDF to a single page-separated text file
# Usage: ocr-pdf.sh input.pdf output.txt
set -euo pipefail

input="$1"
output="$2"
work=$(mktemp -d -t ocr-pdf)
trap 'rm -rf "$work"' EXIT

# 1. Render all pages to 300 DPI PNGs (zero-padded sequence)
pdftoppm -r 300 "$input" "$work/page" -png

# 2. OCR pages in parallel (use all cores)
ls "$work"/page-*.png | xargs -P "$(sysctl -n hw.ncpu)" -I{} \
  tesseract "{}" "{}" --psm 1 2>/dev/null

# 3. Concatenate with page separators
: > "$output"
for txt in "$work"/page-*.png.txt; do
  page=$(basename "$txt" | sed 's/page-0*\([0-9]*\).png.txt/\1/')
  printf '\n\n===== PDF page %s =====\n\n' "$page" >> "$output"
  cat "$txt" >> "$output"
done

echo "OCR complete: $(wc -l < "$output") lines → $output"
```

Page separators (`===== PDF page N =====`) are critical: they let downstream tools map content back to source pages (chapter boundaries, citations, re-OCR requests).

## Quality assessment

Sample 3–5 random pages before trusting bulk output:

```bash
# Check 5 spread-out pages
for p in 1 20 40 60 82; do
  echo "=== page $p ==="
  sed -n "/===== PDF page $p =====/,/===== PDF page /p" out.txt | head -30
done
```

**Typical artifacts** (acceptable for search/reference, not pristine text):
- Fused/split words: "buman" for "human", "modemn" for "modern"
- Stray inverted commas, broken ligatures (`fi`, `fl`)
- Headers merged into body when layout detection slips
- Decorative chapter-title pages may OCR to near-empty — adjacent pages usually carry the content

**Red flags** that mean you should re-OCR:
- Whole pages empty (raise DPI to 400 or change `--psm`)
- Mojibake / non-English characters everywhere (wrong `-l` language)
- Vertical/sideways text mangled (use `--psm 1` for OSD, or pre-rotate with `mogrify -rotate 90`)

## Image OCR (no PDF)

```bash
tesseract scan.jpg out --psm 1          # → out.txt
tesseract scan.jpg - --psm 1            # → stdout
tesseract scan.jpg out --psm 1 pdf      # → out.pdf (searchable)
tesseract scan.jpg out --psm 1 hocr     # → out.hocr (HTML w/ bbox)
tesseract scan.jpg out --psm 1 tsv      # → out.tsv (per-word coords + confidence)
```

For confidence scoring, `tsv` output includes a `conf` column (0–100); low-confidence words below ~60 are usually worth flagging.

## Installation (macOS)

```bash
brew install tesseract poppler           # minimum: OCR + pdftoppm
brew install ocrmypdf                    # optional: cleaner end-to-end PDF flow
brew install tesseract-lang              # optional: 100+ non-English languages
```

`poppler` provides `pdftoppm`, `pdftotext`, `pdfunite`. `tesseract` 5.x ships with English by default.

## Gotchas

- **`ocrmypdf` refuses PDFs that already have text** — use `--force-ocr` to overwrite or `--skip-text` to leave existing pages alone.
- **`pdftoppm` zero-pads filenames** based on page count (`page-01.png` for ≤99 pages, `page-001.png` for ≤999). Glob with `page-*.png` and parse the number from the filename.
- **Large PDFs eat disk** at 300 DPI — a 500-page book renders to ~2 GB of PNGs. Use `/tmp` (or `$TMPDIR`) and trap-cleanup, or batch in chunks.
- **2-up scans** (two book pages per scanned page) are common — detect by aspect ratio (landscape A4 ≈ 842×595 pt). Split before OCR with `pdfjam --landscape --nup 1x2` or `mutool poster -x 2 in.pdf out.pdf`, otherwise tesseract's column detection may fail.
- **Searchable PDF from tesseract** outputs one PDF per page when called per-image. Combine with `pdfunite page-*.pdf out.pdf` or use `ocrmypdf` instead.
