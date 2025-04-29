#!/bin/bash

# Simple wrapper to compile Arduino sketches using Docker

# Extract flags first
flags=()
while [[ "$1" == --* ]]; do
    flags+=("$1")
    shift
done

if [ $# -lt 2 ]; then
  echo "Usage: $0 [--disable-core-cache] [--disable-library-cache] <sketch_directory> <fqbn> [library1 library2 ...]"
  echo "  --disable-core-cache: Clear the entire Arduino cache before compiling"
  echo "  --disable-library-cache: Clear only the Arduino sketches cache before compiling"
  echo "  sketch_directory: Path to the Arduino sketch directory"
  echo "  fqbn: Fully Qualified Board Name (e.g., arduino:avr:uno)"
  echo "  libraries: Optional list of libraries to install before compilation"
  exit 1
fi

sketch_dir=$(realpath "$1")
fqbn="$2"
shift 2
libraries=("$@")

# Extract sketch name from directory
sketch_name=$(basename "$sketch_dir")

# Create output directory, for now just inside the sketch directory
output_dir="$sketch_dir/build"
mkdir -p "$output_dir"

echo "Compiling sketch: $sketch_name for board: $fqbn"

# Run Docker container (compile.sh is the entrypoint)
docker run --cpus=1 --rm \
  -v "$sketch_dir:/sketches/$sketch_name" \
  -v "$output_dir:/output" \
  arduino-builder \
  "${flags[@]}" "$sketch_name" "$fqbn" "${libraries[@]}"
