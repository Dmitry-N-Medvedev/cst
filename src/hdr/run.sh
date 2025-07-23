#!/bin/bash
set -euo pipefail

zig build -Doptimize=ReleaseFast

/usr/bin/time /bin/bash -c '
{
  for dir in /Users/dmitrymedvedev/projects/cst/.data/part000000/*/; do
    if [ -d "$dir" ]; then
      zig-out/bin/hdr --dir "$dir"
      printf "."
    fi
  done
  printf "\n"
}
'
