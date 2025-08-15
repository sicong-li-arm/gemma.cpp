codex
Below is the quickest way to get a libgemma.so out of the existing CMake build—no CMakeLists edits required.

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## How it works

In your top‑level CMakeLists.txt you’ll find (around line 123):

    ## Library Target

    add_library(libgemma ${SOURCES})
    set_property(TARGET libgemma PROPERTY CXX_STANDARD 17)
    set_target_properties(libgemma PROPERTIES PREFIX "")
    set_property(TARGET libgemma PROPERTY POSITION_INDEPENDENT_CODE ON)
    …
    install(TARGETS libgemma DESTINATION lib)

CMakeLists.txt

Because the call to add_library(libgemma ${SOURCES}) does not explicitly say STATIC or SHARED, it will honor CMake’s global BUILD_SHARED_LIBS switch.  By default BUILD_SHARED_LIBS is OFF, so CMake makes a static .a.  If you set it to ON, the same add_library(...) invocation will
instead produce a shared library (.so on Linux, .dylib on macOS, etc.).

The fact that POSITION_INDEPENDENT_CODE is already turned on (line 126) means all your objects are PIC‑safe and a shared object can be emitted without further edits.

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Build steps

From your project root:

    mkdir -p build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON
    cmake --build . --target libgemma

That will give you:

    $ ls lib/libgemma.*
    lib/libgemma.so    # <- shared library
    lib/libgemma.so.0  # <- versioned soname if your platform/toplevel CMake policy adds it

You can then install it (if desired) via:

    cmake --build . --target install

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## (Optional) Using CMakePresets

If you prefer to drive this via your existing CMakePresets.json, you can add a preset that injects BUILD_SHARED_LIBS=ON. For example, append to your configurePresets array:

    diff --git a/CMakePresets.json b/CMakePresets.json
    index ... 100644
    --- a/CMakePresets.json
    +++ b/CMakePresets.json
    @@
         {
           "name": "make",
           "inherits": "__defaults__",
           "displayName": "Make",
           "description": "Unix Makefiles",
           "generator": "Unix Makefiles",
           "binaryDir": "${sourceDir}/build"
    +    },
    +    {
    +      "name": "make-shared",
    +      "inherits": "make",
    +      "cacheVariables": {
    +        "BUILD_SHARED_LIBS": "ON"
    +      }
         },

CMakePresets.json

Then:

    cmake --preset make-shared
    cmake --build build --target libgemma

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

### Summary

    * **No CMakeLists edits needed**—the existing `add_library(libgemma …)` honors `BUILD_SHARED_LIBS`.
    * Turn on `-DBUILD_SHARED_LIBS=ON` when you run CMake to switch from `.a` to `.so`.
    * Optionally, add a “make-shared” preset in `CMakePresets.json` for convenience.

Let me know if you’d rather have a permanently dual‐build (both static + shared) in CMakeLists, but for now the above is the simplest way to get libgemma.so.
