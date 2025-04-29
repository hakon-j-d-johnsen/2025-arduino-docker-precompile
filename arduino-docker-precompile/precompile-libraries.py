#!/usr/bin/env -S python3 -u
import sys, subprocess, hashlib, shutil, itertools
from pathlib import Path

def precompile(fqbn, libraries, includes):
    """
    Precompiles the libraries for a given board using arduino-cli.
    Args:
        fqbn (str): The fully qualified board name.
        libraries (list): List of library names to install.
        includes (list): List of header files to include in the sketch so that arduino-cli chooses to compile them
    """
    print(f"Precompiling libraries for {fqbn} with libraries: {', '.join(libraries)}")
    # Install the libraries
    subprocess.run(["arduino-cli", "lib", "install"] + libraries, check=True)

    # We give the sketch a unique name based on fqbn and the hash of the installed libraries,
    # so that we can reuse the cache if we later compile with the same fqbn and libraries.
    lib_hash = hashlib.md5(subprocess.check_output(["arduino-cli", "lib", "list"])).hexdigest()
    sketch_dir = Path(f"/tmp/{fqbn}-{lib_hash}")
    sketch_dir.mkdir(exist_ok=True)

    # Write sketch file
    with open(sketch_dir / f"{sketch_dir.name}.ino", "w") as f:
        f.write('\n'.join([f"#include <{inc}>" for inc in includes]) + '\n\n')
        f.write("void setup() {}\nvoid loop() {}\n")
    try:
        subprocess.run(["arduino-cli", "compile", "--fqbn", fqbn, str(sketch_dir)], check=True)
    except subprocess.CalledProcessError:
        print(f"Failed to precompile libraries for {fqbn}, continuing...")

    # Clean up
    shutil.rmtree("/root/Arduino/libraries", ignore_errors=True)
    shutil.rmtree(sketch_dir, ignore_errors=True)

# Example of precompiling some libraries for some ESP32 boards
for fqbn in ["esp32:esp32:esp32c6", "esp32:esp32:esp32s3"]: 
    popular_library_data = [
        ("U8g2", "U8g2lib.h"),
        ("FastLED", "FastLED.h"),
        ("Adafruit MPU6050", "Adafruit_MPU6050.h"),
    ]
    # Let's select any combination of 1 or 2 libraries from the list to precompile
    for n in range(1, 3):
        for libraries in itertools.combinations(popular_library_data, n):
            library_names = [lib[0] for lib in libraries]
            library_includes = [lib[1] for lib in libraries]
            precompile(fqbn, library_names, library_includes)