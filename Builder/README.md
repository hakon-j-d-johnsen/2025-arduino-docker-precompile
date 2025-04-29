# Proof of concept for precompiling Arduino cores and libraries in a docker image

## Core precompilation
Precompiling a core is trivial - just compile an empty sketch for the fqbn.

## Library precompilation
Precompiling a library is a bit more involved, because the builting caching logic only caches compiled libraries local to a sketch, and not in a global cache. Additionally, each library is compiled with each other installed library in its include path, so any combination of installed libraries can have intended or unintended effects on each other.

We therefore need to compile each of the most common library combinations, and need to use the same sketch name to trick the arduino-cli into using this cache if the library and fqbn matches.

## Process

**Precompilation:**
For each fqbn and library combination that we want to precompile:
1. Install the libraries, and calculate the hash of `arduino-cli lib list --format json`.
2. Create a simple temporary sketch `/tmp/<fqbn>-<library_hash>/`, which includes header files from each installed library, and compile it. This compiles all the libraries and stores them in the cache keyed by the sketch name.

**Using the cache**
When we compile a new sketch, we recalculate <precompile_hash> and store the new sketch in `/tmp/<fqbn>-<library_hash>/`. This way, the cache is automatically used if it exists.

## Other alternatives

**Not using the same sketch name:**
If we don't use the same sketch name, there is another option to trick arduino-cli into reusing the cache.
Library compilation cache is stored in `/root/.cache/arduino/sketches/<hash>/libraries/`, where `<hash>` is the uppercase hex md5sum of the path to the hash (without trailing slash).
We could then do the following:
1. Copy library cache from `/root/.cache/arduino/sketches/<cache_hash>/libraries/` to `/root/.cache/arduino/sketches/<sketch_hash>/libraries/`. `cache_hash` is the md5sum of `/tmp/<fqbn>-<library_hash>` (the precompiled sketch directory), and `sketch_hash` is the md5sum of the sketch path (without trailing slash).
2. Loop through all .d files in `/root/.cache/arduino/sketches/<sketch_hash>/libraries/` and `cache_hash` with `sketch_hash`. Otherwise, arduino-cli will detect that the path to the compiled object files is different from where it was compiled to, and choose not to use the cache.

**Cache arbitrary combinations of libraries:**
Ideally, we would want to be able to use one precompiled library even if the exact list of libraries does not match. But the problem is that we then need to more carefully analyze the interaction between different libraries since they are in each other's include path. So it's not as straightforward. Maybe we would have to use ccache or something instead. 