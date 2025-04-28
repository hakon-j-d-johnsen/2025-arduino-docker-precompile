#!/bin/bash

# A simple wrapper script to call compile.sh inside a Docker container

# Check if required arguments are provided
if [ $# -lt 2 ]; then
  echo "Usage: $0 <sketch_directory> <fqbn> [library1 library2 ...]"
  echo "  sketch_directory: Path to the Arduino sketch directory"
  echo "  fqbn: Fully Qualified Board Name (e.g., arduino:avr:uno)"
  echo "  libraries: Optional list of libraries to install before compilation"
  exit 1
fi

SKETCH_DIR=$(realpath "$1")
FQBN="$2"
LIBRARIES="${@:3}"

# Extract sketch name from directory
SKETCH_NAME=$(basename "$SKETCH_DIR")

# Create a temporary output directory
OUTPUT_DIR="$SKETCH_DIR/build"
mkdir -p "$OUTPUT_DIR"

echo "Starting Docker container to compile sketch: $SKETCH_NAME for board: $FQBN"

# Run Docker container for compilation
docker run --rm \
  -v "$SKETCH_DIR:/sketches/$SKETCH_NAME" \
  -v "$OUTPUT_DIR:/output" \
  arduino-builder \
  /compile.sh "$SKETCH_NAME" "$FQBN" $LIBRARIES

COMPILE_STATUS=$?

if [ $COMPILE_STATUS -eq 0 ]; then
  echo "Compilation successful!"
  echo "Output files are in: $OUTPUT_DIR"
else
  echo "Compilation failed with status $COMPILE_STATUS"
fi

exit $COMPILE_STATUS
