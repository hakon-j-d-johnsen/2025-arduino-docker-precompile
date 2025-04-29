#!/bin/bash
set -e

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <fqbn> [library1:include1 library2:include2 ...]"
  echo "Example: $0 arduino:avr:uno Servo:Servo.h \"MFRC522:MFRC522.h\""
  exit 1
fi

fqbn="$1"
shift

# Extract libraries and includes
libraries=()
includes=()

for pair in "$@"; do
  # Check if there's at least one colon in the string
  if [[ "$pair" == *":"* ]]; then
    # Get everything before the last colon for library
    lib="${pair%:*}"
    
    # Get everything after the last colon for include
    inc="${pair##*:}"
    
    libraries+=("$lib")
    includes+=("$inc")
  else
    echo "Warning: No include file specified for $pair, skipping"
    continue
  fi
done

# Install all libraries
echo "Installing libraries: ${libraries[*]}"
if [ ${#libraries[@]} -gt 0 ]; then
  arduino-cli lib install "${libraries[@]}"
fi

# Calculate hash of installed libraries
library_hash=$(arduino-cli lib list --format json | md5sum | awk '{print $1}')
echo "Library hash: ${library_hash}"

sketch_name="${fqbn}-${library_hash}"
sketch_dir="/tmp/${sketch_name}"
mkdir -p "${sketch_dir}"

# Create sketch with includes for all libraries
echo "Creating sketch with library includes"
{
  # Add includes specified by the user
  for inc in "${includes[@]}"; do
    echo "#include <${inc}>"
  done
  echo ""
  echo "void setup() {}"
  echo "void loop() {}"
} > "${sketch_dir}/${sketch_name}.ino"

# Compile the sketch, which then compiles all libraries
echo "Precompiling libraries for ${fqbn}"
arduino-cli compile --fqbn "${fqbn}" "${sketch_dir}" || echo "Failed to precompile libraries for ${fqbn}, continuing..."

# Remove all the installed libraries but keep the downloaded archives
rm -rf /root/Arduino/libraries

echo "Done precompiling"
