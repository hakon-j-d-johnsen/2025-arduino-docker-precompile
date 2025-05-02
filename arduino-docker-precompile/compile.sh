#!/bin/bash

# Simplistic parsing of some optional flags
while [[ "$1" == --* ]]; do
    if [ "$1" == "--disable-core-cache" ]; then
        echo "Clearing the entire Arduino cache..."
        rm -rf /root/.cache/arduino
    elif [ "$1" == "--disable-library-cache" ]; then
        echo "Clearing only the Arduino sketches cache..."
        rm -rf /root/.cache/arduino/sketches
    fi
    shift
done

if [ $# -lt 2 ]; then
    echo "Usage: $0 [--disable-core-cache] [--disable-library-cache] <orig_sketch_name> <fqbn> [library1 library2 ...]"
    exit 1
fi

orig_sketch_name=$1
fqbn=$2
# Shift twice to remove the first two arguments, leaving only libraries
shift 2
libraries=("$@")

echo "Compiling ${orig_sketch_name} for ${fqbn}"
if [ ${#libraries[@]} -gt 0 ]; then
    arduino-cli lib install "${libraries[@]}"
    # Installing libraries sets their mtime to now, which invalidates the cache. We already
    # match the cache on exact set of installed library versions, so we can safely set the mtime to 
    # a long time ago.
    find /root/Arduino/libraries -type f -exec touch -m -t 197001010000 {} \;
fi

# We key the cache on fqbn and the hash of the installed libraries. By using this
# as the sketch name, arduino-cli will use the same cache for the same set of libraries.
lib_hash=$(arduino-cli lib list | md5sum | cut -d' ' -f1)
sketch_name="${fqbn}-${lib_hash}"
sketch_dir="/tmp/${sketch_name}"

# Copy our sketch from the mounted directory to the directory with the right cache key
cp -r "/sketches/${orig_sketch_name}" "${sketch_dir}"
# And rename the main sketch file to match
mv "${sketch_dir}/${orig_sketch_name}.ino" "${sketch_dir}/${sketch_name}.ino"

# Compile
arduino-cli compile  \
    --fqbn "${fqbn}" \
    --output-dir "/output" \
    "${sketch_dir}"

# Clean up sketch directory
rm -rf "${sketch_dir}"