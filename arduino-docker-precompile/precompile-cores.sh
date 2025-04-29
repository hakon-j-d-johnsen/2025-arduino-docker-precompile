#!/bin/bash
set -e

mkdir -p /tmp/compile-core
echo -e "void setup() {}\nvoid loop() {}" > /tmp/compile-core/compile-core.ino

# Loop through all FQBNs given as arguments to the script
for fqbn in "$@"; do
  # Compile the empty sketch, which just compiles the core
  echo "Compiling core for ${fqbn}"
  arduino-cli compile --fqbn "${fqbn}" "/tmp/compile-core"
done