#!/bin/bash
set -e

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 fqbn1 fqbn2 ..."
  exit 1
fi

sketch_name="compile-core"
sketch_dir="/tmp/${sketch_name}"
mkdir -p "${sketch_dir}"

{
  echo "void setup() {}"
  echo "void loop() {}"
} > "${sketch_dir}/${sketch_name}.ino"

# Loop through all FQBNs
for fqbn in "$@"; do
  # Compile the sketch, which then compiles all libraries
  echo "Compiling core for ${fqbn}"
  # If arduino-cli compile fails, we just continue with the next command
  arduino-cli compile --fqbn "${fqbn}" "${sketch_dir}" || echo "Failed to compile core for ${fqbn}, continuing..."
done
