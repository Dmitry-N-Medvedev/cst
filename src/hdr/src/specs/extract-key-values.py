#!/usr/bin/env python3

import os
import csv
from pathlib import Path
from collections import defaultdict

ROOT_DIR = Path("../../../../.data/part000000")
OUTPUT_DIR = Path("./aggregated/")
STATS_CSV_PATH = OUTPUT_DIR / "stats.csv"
os.makedirs(OUTPUT_DIR, exist_ok=True)

KNOWN_KEYS = [
    "FILE", "ACCESS", "FORM", "RECL", "FORMAT", "CONTENT", "CONFIG",
    "NDIMENS", "DIMENS", "GENLAB", "VARIAB", "VARUNIT",
    "AXISLAB", "AXIUNIT", "AXIMETH", "AXIVAL", "MIN", "STEP", "NVARS",
    "ULOADS", "MAXTIME", "MINTIME", "MEAN"
]
KNOWN_KEYS_SET = set(KNOWN_KEYS)

key_lines = defaultdict(list)
key_stats = {key: {"min": float("inf"), "max": 0} for key in KNOWN_KEYS}

file_size_min = float("inf")
file_size_max = 0

def is_valid_file(path: Path) -> bool:
    return path.is_file() and '%' in path.suffix

def update_line_stats(key, line):
    length = len(line.encode("utf-8"))
    key_stats[key]["min"] = min(key_stats[key]["min"], length)
    key_stats[key]["max"] = max(key_stats[key]["max"], length)

def update_block_stats(key, block_lines):
    block = "\n".join(block_lines)
    length = len(block.encode("utf-8"))
    key_stats[key]["min"] = min(key_stats[key]["min"], length)
    key_stats[key]["max"] = max(key_stats[key]["max"], length)

for file_dir in ROOT_DIR.iterdir():
    if not file_dir.is_dir():
        continue

    for file_path in file_dir.rglob("*"):
        if not is_valid_file(file_path):
            continue

        # Update file size stats
        file_size = file_path.stat().st_size
        file_size_min = min(file_size_min, file_size)
        file_size_max = max(file_size_max, file_size)

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
                                break
                            block_lines.append(next_line)

                        key_lines["ULOADS"].extend(block_lines)
                        update_block_stats("ULOADS", block_lines)

                        # Process next_line after breaking out of ULOADS block
                        if next_head in KNOWN_KEYS_SET:
                            current_key = next_head
                            key_lines[current_key].append(next_line)
                            if current_key != "ULOADS":
                                update_line_stats(current_key, next_line)
                        continue  # skip to next outer loop iteration
                    else:
                        key_lines[current_key].append(line)
                        update_line_stats(current_key, line)
                else:
                    if current_key:
                        key_lines[current_key].append(line)
                        if current_key != "ULOADS":
                            update_line_stats(current_key, line)
        print(f"processing\t{file_path}")

# Write out collected data
for key in KNOWN_KEYS:
    if key in key_lines:
        with (OUTPUT_DIR / f"{key}.txt").open("w", encoding="utf-8") as out:
            out.write("\r\n".join(key_lines[key]))
            out.write("\r\n")
        print(f"writing:\t{key}")

# Write stats to CSV
with STATS_CSV_PATH.open("w", newline="", encoding="utf-8") as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=["KEY", "MIN_LENGTH_BYTES", "MAX_LENGTH_BYTES"])
    writer.writeheader()

    for key in KNOWN_KEYS:
        stats = key_stats[key]
        if stats["min"] != float("inf"):
            writer.writerow({
                "KEY": key,
                "MIN_LENGTH_BYTES": stats["min"],
                "MAX_LENGTH_BYTES": stats["max"]
            })
        else:
            writer.writerow({
                "KEY": key,
                "MIN_LENGTH_BYTES": "",
                "MAX_LENGTH_BYTES": ""
            })

    # Add FILE_SIZE stats row
    writer.writerow({
        "KEY": "FILE_SIZE",
        "MIN_LENGTH_BYTES": file_size_min if file_size_min != float("inf") else "",
        "MAX_LENGTH_BYTES": file_size_max if file_size_max != 0 else ""
    })

print(f"\nCSV written to: {STATS_CSV_PATH}")

