#!/bin/bash

# Script to be run inside the Docker container to compile Arduino sketches
# Assumes the sketch is mounted at /sketches/<sketch_name>

# Check if required arguments are provided
if [ $# -lt 2 ]; then
  echo "Usage: $0 <sketch_name> <fqbn> [library1 library2 ...]"
  echo "  sketch_name: Name of the Arduino sketch (mounted at /sketches/<sketch_name>)"
  echo "  fqbn: Fully Qualified Board Name (e.g., arduino:avr:uno)"
  echo "  libraries: Optional list of libraries to install before compilation"
  exit 1
fi

SKETCH_NAME="$1"
FQBN="$2"
LIBRARIES="${@:3}"

echo "Compiling sketch with name $SKETCH_NAME"

SKETCH_DIR="/sketches/$SKETCH_NAME"
OUTPUT_DIR="/output"

echo "Compiling sketch: $SKETCH_NAME for board: $FQBN"

# Install libraries if specified
if [ ! -z "$LIBRARIES" ]; then
  echo "Installing libraries: $LIBRARIES"
  arduino-cli lib install $LIBRARIES
fi

# Try to use pre-compiled libraries if available
echo "/root/precompile_sketches/$FQBN"
CACHE_HASH=$(echo -n "/root/precompile_sketches/$FQBN" | md5sum | cut -d' ' -f1 | tr '[:lower:]' '[:upper:]')
SKETCH_HASH=$(echo -n "$SKETCH_DIR" | md5sum | cut -d' ' -f1 | tr '[:lower:]' '[:upper:]')

if [ -d "/root/.cache/arduino/sketches/$CACHE_HASH/libraries" ]; then
  echo "Using pre-compiled libraries for $FQBN"
  mkdir -p "/root/.cache/arduino/sketches/$SKETCH_HASH/libraries"
  cp -r "/root/.cache/arduino/sketches/$CACHE_HASH/libraries"/* \
       "/root/.cache/arduino/sketches/$SKETCH_HASH/libraries/"
fi

# CACHE_HASH with SKETCH_HASH in all .d files
find "/root/.cache/arduino/sketches/$SKETCH_HASH/libraries/" -type f -name "*.d" -exec sed -i "s/$CACHE_HASH/$SKETCH_HASH/g" {} \;


# Compile the sketch
arduino-cli compile \
  --fqbn "$FQBN" \
  "$SKETCH_DIR" -v


COMPILE_STATUS=$?

if [ $COMPILE_STATUS -eq 0 ]; then
  echo "Compilation successful!"
  echo "Output files are in: $OUTPUT_DIR"
else
  echo "Compilation failed with status $COMPILE_STATUS"
fi
cp "/root/.cache/arduino/sketches/$SKETCH_HASH/$SKETCH_NAME"* "$OUTPUT_DIR/"

exit $COMPILE_STATUS
