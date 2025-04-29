# Precompilation proof of concept
This is a proof of concept for pre-compiling Arduino cores and libraries using arduino-cli's built-in caching functionality. This way we can build a Docker image which is ready to compile Arduino sketches where much of the common code is pre-compiled. The pre-compilation is divided into two parts: the core and the libraries. 

**Core precompilation**

Precompiling and caching a core is trivial - just compile an empty sketch for the fqbn, and arduino-cli already stores it in its cache shared among all future sketches. (However, we need to compile without using `--build-path`, otherwise arduino-cli disables its default builtin cache.)

**Library precompilation**

Precompiling and caching a library is a bit more involved, because the builtin Arduino caching logic only caches compiled libraries local to a sketch name. Library caches are not shared across sketches. Additionally, each library is compiled with all other installed libraries in its include path, so any combination of installed libraries can potentially affect each other intentionally or unintentionally.

We can utilize this functionality to make a simple cache: We give our sketch a special name before compiling it, depedning on the fqbn and a hash of all installed libraries (with their version). This way, we will have a unique set of separate caches for each library combination for each fqbn.

This cache can be used both for precompilation (if we compile sketches with the specific libraries and fqbn during docker build), and for regular caching (if the same instance keeps running to compile multiple sketches).

## How to test

Build the docker image (this will take some time as it precompiles a few different cores and library combinations):
```bash
docker build -t arduino-docker-precompile arduino-docker-precompile
```

Now we can use it to test how long it takes to build a test sketch (while using only 1 cpu):

```bash
time ./compile-wrapper.sh ./testsketch esp32:esp32:esp32c6 "Adafruit MPU6050" 
[...]
Sketch uses 299405 bytes (22%) of program storage space. Maximum is 1310720 bytes.
Global variables use 15484 bytes (4%) of dynamic memory, leaving 312196 bytes for local variables. Maximum is 327680 bytes.
./compile-wrapper.sh ./testsketch esp32:esp32:esp32c6 "Adafruit MPU6050"  0.01s user 0.02s system 0% cpu 4.718 total
```

We can compare this to the time without library cache:
```bash
> time ./compile-wrapper.sh --disable-library-cache ./testsketch esp32:esp32:esp32c6 "Adafruit MPU6050"
[...]
Sketch uses 299405 bytes (22%) of program storage space. Maximum is 1310720 bytes.
Global variables use 15484 bytes (4%) of dynamic memory, leaving 312196 bytes for local variables. Maximum is 327680 bytes.
./compile-wrapper.sh --disable-library-cache ./testsketch esp32:esp32:esp32c6  0.01s user 0.01s system 0% cpu 13.568 total
```

And the time with no cache:
```bash
> time ./compile-wrapper.sh --disable-library-cache --disable-core-cache ./testsketch esp32:esp32:esp32c6 "Adafruit MPU6050"
[...]
Sketch uses 299405 bytes (22%) of program storage space. Maximum is 1310720 bytes.
Global variables use 15484 bytes (4%) of dynamic memory, leaving 312196 bytes for local variables. Maximum is 327680 bytes.
./compile-wrapper.sh --disable-library-cache --disable-core-cache ./testsketc  0.01s user 0.02s system 0% cpu 42.123 total
```
**Summary of single-core compilation times for this sketch using Adafruit MPU6050 library on ESP32-C6:**
- No cache: 42.12 s
- Core cache: 13.56 s
- Full cache: 4.72 s

**Specifying which library combinations to precompile**

This is done by specifying libraries and headers to include (to make arduino-cli include the respective libraries) in `arduino-docker-precompile/precompile-libraries.py`.

## How it works

In the dockerfile, we precompile some cores and libraries, simply by compiling them (while being smart with the sketch name for different library combinations). If we then use the same docker image to compile a sketch using the same fqbn and library combination, the cache will be used automatically.

**Precompilation:**

For each fqbn and library combination that we want to precompile:
1. We install the libraries, and calculate the hash of `arduino-cli lib list`.
2. We create a simple temporary sketch `/tmp/<fqbn>-<library_hash>/`, which includes header files from each installed library, and compile it. This compiles all the libraries and stores them in the cache keyed by the sketch name.

**Using the cache**

When we compile a new sketch, we recalculate the hash of `arduino-cli lib list` and store the new sketch in `/tmp/<fqbn>-<library_hash>/`. This way, the cache is automatically used if it exists.

**Expanding the cahce**

In this demo, the docker image is ephemeral and we only benefit from the cache that was built during the docker build process. However if the docker image instead is kept running to compile multiple sketches, any new combination of fqbn and library combination should automatically be cached.

**Storage requirements**

Each combination of fqbn and set of installed libraries is a few to a few tens of MB. If we want to expand the cahce to hundreds or thousands of different library combinations, the size could become an issue. However this could potentially be mitigated:

- The only relevant files are in `/root/.cache/arduino/<uppercase md5sum of full library path without trailing slash>/libraries`. All other files in `/root/.cache/arduino/<uppercase md5sum of full library path without trailing slash>/` can be purged.
- Many of the object files in `/root/.cache/arduino/<uppercase md5sum of full library path without trailing slash>/libraries` are duplicates of the same object files with other library combinations. We can use e.g. a deduplication tool at regular intervals, or a filesystem with deduplication support.
- We can prune the oldest caches if necessary.