#!/usr/bin/env python3
import sys
import os
import subprocess
import shutil
import tempfile

def run_command(cmd):
    """Run a command and return its output"""
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        sys.exit(1)
    return result.stdout

def main():
    if len(sys.argv) < 2:
        print("Usage: precompile.py <fqbn> [library1 library2 ...]")
        sys.exit(1)
    
    fqbn = sys.argv[1]
    libraries = sys.argv[2:]
    
    sketch_name = fqbn
    sketch_dir = f"/root/precompile_sketches/{sketch_name}"
    os.makedirs(sketch_dir, exist_ok=True)
    
    # Install all libraries
    run_command(["arduino-cli", "lib", "install"] + libraries)
    
    # Create sketch with includes for all libraries
    sketch_content = []
    for library in libraries:
        # Look for first .h file in /root/Arduino/libararies/<library>/src
        library_path = f"/root/Arduino/libraries/{library}/src"
        if os.path.exists(library_path):
            for root, dirs, files in os.walk(library_path):
                for file in files:
                    if file.endswith(".h"):
                        # Add the include statement
                        sketch_content.append(f"#include <{file}>")
                        break
                else:
                    continue
                break
        else:
            print(f"Library path not found: {library_path}")
            continue
    
    sketch_content.extend([
        "void setup() {}",
        "void loop() {}"
    ])
    
    # Write sketch file
    with open(f"{sketch_dir}/{sketch_name}.ino", "w") as f:
        f.write("\n".join(sketch_content))
    
    # Compile the sketch, which then compiles all libraries
    print(f"Compiling sketch for {fqbn}")
    run_command(["arduino-cli", "compile", "--fqbn", fqbn, sketch_dir])

    # Save library list of precompiled libraries
    libraries_list = run_command(["arduino-cli", "lib", "list", "--format", "json"])
    with open(f"{sketch_dir}/libraries.json", "w") as f:
        f.write(libraries_list)
    
    # Remove all the installed libraries (but we keep the downloaded compressed archives so that reinstalling is fast)
    shutil.rmtree("/root/Arduino/libraries")
    
    print("Done precompiling")

if __name__ == "__main__":
    main()
