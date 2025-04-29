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

ORIG_SKETCH_NAME="$1"
FQBN="$2"
LIBRARIES="${@:3}"

echo "Compiling sketch with orig name $ORIG_SKETCH_NAME (for $FQBN), with libraries $LIBRARIES"

echo "Compiling sketch with name $ORIG_SKETCH_NAME"

ORIG_SKETCH_DIR="/sketches/$ORIG_SKETCH_NAME"
OUTPUT_DIR="/output"

echo "Compiling sketch: $ORIG_SKETCH_NAME for board: $FQBN"

# Install libraries if specified # TODO: Properly array because library can have spaces
if [ ! -z "$LIBRARIES" ]; then
  echo "Installing libraries: $LIBRARIES"
  arduino-cli lib install $LIBRARIES
fi
# Set mtime to 0 for all files in /root/Arduino/libraries
echo "Setting mtime"
find /root/Arduino/libraries -type f -exec touch -m -t 197001010000 {} \;

echo "Calculating hash"
library_hash=$(arduino-cli lib list --format json | md5sum | awk '{print $1}')
echo "Library hash: ${library_hash}"

SKETCH_NAME="${FQBN}-${library_hash}"
SKETCH_DIR="/tmp/${SKETCH_NAME}"
echo "Using sketch dir $SKETCH_DIR. Does it exist? $(ls -la $SKETCH_DIR)"
rm -rf "$SKETCH_DIR" || true

cp -r "$ORIG_SKETCH_DIR" "$SKETCH_DIR"
mv "$SKETCH_DIR/$ORIG_SKETCH_NAME.ino" "$SKETCH_DIR/$SKETCH_NAME.ino"

# Compile the sketch
arduino-cli compile \
  --fqbn "$FQBN" \
  "$SKETCH_DIR"


COMPILE_STATUS=$?

if [ $COMPILE_STATUS -eq 0 ]; then
  echo "Compilation successful!"
  echo "Output files are in: $OUTPUT_DIR"
else
  echo "Compilation failed with status $COMPILE_STATUS"
fi
SKETCH_HASH=$(echo -n "$SKETCH_DIR" | md5sum | cut -d' ' -f1 | tr '[:lower:]' '[:upper:]')
cp "/root/.cache/arduino/sketches/$SKETCH_HASH/$SKETCH_NAME"* "$OUTPUT_DIR/"

exit $COMPILE_STATUS
