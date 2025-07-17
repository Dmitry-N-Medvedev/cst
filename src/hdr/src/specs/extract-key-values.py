#!/usr/bin/env python3

import os
from pathlib import Path
from collections import defaultdict

INPUT_DIR = "../../../../.data/3.1_s11"   # Change to your input directory
OUTPUT_DIR = "./aggregated/"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# List of known keys to extract
KNOWN_KEYS = [
    "FILE", "ACCESS", "FORM", "RECL", "FORMAT", "CONTENT", "CONFIG",
    "NDIMENS", "DIMENS", "GENLAB", "VARIAB", "VARUNIT",
    "AXISLAB", "AXIUNIT", "AXIMETH", "AXIVAL", "MIN", "STEP", "NVARS",
    "ULOADS", "MAXTIME", "MINTIME", "MEAN"
]
KNOWN_KEYS_SET = set(KNOWN_KEYS)

key_lines = defaultdict(list)

def is_valid_file(path: Path) -> bool:
    return path.is_file() and '%' in path.suffix

for file_path in Path(INPUT_DIR).rglob("*"):
    if not is_valid_file(file_path):
        continue

    with file_path.open("r", encoding="utf-8") as f:
        current_key = None
        lines_iter = iter(f)
        for line in lines_iter:
            line = line.rstrip()
            if not line:
                continue

            split = line.split(maxsplit=1)
            head = split[0]

            if head in KNOWN_KEYS_SET:
                current_key = head

                if current_key == "ULOADS":
                    block_lines = [line]
                    for next_line in lines_iter:
                        next_line = next_line.rstrip()
                        if not next_line:
                            continue
                        next_head = next_line.split(maxsplit=1)[0]
                        if next_head in KNOWN_KEYS_SET:
                            current_key = next_head
                            break
                        block_lines.append(next_line)

                    key_lines["ULOADS"].extend(block_lines)

                    # Reprocess next_line if we encountered a new key
                    if current_key != "ULOADS" and next_line:
                        line = next_line
                        split = line.split(maxsplit=1)
                        head = split[0]
                        if head in KNOWN_KEYS_SET:
                            current_key = head
                        # Fall through to append this key normally

                else:
                    key_lines[current_key].append(line)

            else:
                if current_key:
                    key_lines[current_key].append(line)

# Write each key’s lines to a separate file
for key in KNOWN_KEYS:
    if key in key_lines:
        with open(os.path.join(OUTPUT_DIR, f"{key}.txt"), "w", encoding="utf-8") as out:
            out.write("\r\n".join(key_lines[key]))
            out.write("\r\n")

