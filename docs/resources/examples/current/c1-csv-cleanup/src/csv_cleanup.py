#!/usr/bin/env python3
# SPDX-License-Identifier: MIT

import csv
import sys
from pathlib import Path

HEADER_MAP = {
    "item name": "item_name",
    "item": "item_name",
    "qty": "quantity",
    "quantity": "quantity",
    "location": "location",
}


def normalize_header(value: str) -> str:
    key = value.strip().lower().replace("_", " ")
    return HEADER_MAP.get(key, key.replace(" ", "_"))


def clean_csv(input_path: Path, output_path: Path) -> int:
    if not input_path.exists():
        print(f"input file not found: {input_path}", file=sys.stderr)
        return 2
    if input_path.resolve() == output_path.resolve():
        print("input and output paths must differ", file=sys.stderr)
        return 2
    with input_path.open(newline="", encoding="utf-8") as source:
        reader = csv.reader(source)
        rows = list(reader)
    if not rows:
        output_path.write_text("", encoding="utf-8")
        return 0
    headers = [normalize_header(cell) for cell in rows[0]]
    cleaned = [headers]
    for row in rows[1:]:
        padded = row + [""] * (len(headers) - len(row))
        normalized = [cell.strip() for cell in padded[: len(headers)]]
        if any(normalized):
            cleaned.append(normalized)
    with output_path.open("w", newline="", encoding="utf-8") as target:
        writer = csv.writer(target, lineterminator="\n")
        writer.writerows(cleaned)
    return 0


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: csv_cleanup.py INPUT.csv OUTPUT.csv", file=sys.stderr)
        return 2
    return clean_csv(Path(argv[1]), Path(argv[2]))


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
