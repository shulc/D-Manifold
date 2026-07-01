cmake_minimum_required(VERSION 3.18)
project(d_manifold CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ---- Vendored Manifold (extern/manifold submodule, pinned to v3.5.2) --------
# Build only what we need:
#   manifoldc   - the official C FFI bindings (target we link against)
#   manifold    - the core C++ library (linked transitively through manifoldc)
# Strip everything else: tests, Python bindings, parallel TBB backend,
# samples, extras.  Clipper2 (CrossSection backend) is pulled automatically
# via FetchContent as a static library when it is not found on the system.

set(MANIFOLD_TEST     OFF CACHE BOOL "" FORCE)
set(MANIFOLD_PYBIND   OFF CACHE BOOL "" FORCE)
set(MANIFOLD_JSBIND   OFF CACHE BOOL "" FORCE)
set(MANIFOLD_PAR      OFF CACHE BOOL "" FORCE)
set(MANIFOLD_DEBUG    OFF CACHE BOOL "" FORCE)
set(MANIFOLD_ASSERT   OFF CACHE BOOL "" FORCE)
set(MANIFOLD_STRICT   OFF CACHE BOOL "" FORCE)
set(MANIFOLD_CROSS_SECTION    ON  CACHE BOOL "" FORCE)
set(MANIFOLD_CBIND            ON  CACHE BOOL "" FORCE)
set(MANIFOLD_USE_BUILTIN_CLIPPER2 OFF CACHE BOOL "" FORCE)
set(MANIFOLD_DOWNLOADS        ON  CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS         OFF CACHE BOOL "" FORCE)

# Manifold unconditionally registers install(EXPORT manifoldTargets …).
# With tests / samples off the export set may be sparse; and we never
# install (this build is a build-time dependency of the D package).
# Shadow `install` with a no-op for the duration of add_subdirectory —
# same technique as D-OpenSubdiv uses for OpenSubdiv.
function(install)
endfunction()

add_subdirectory(extern/manifold EXCLUDE_FROM_ALL)

# Pull manifoldc (+ its transitive deps: manifold, Clipper2) into the
# default build on every generator.  Without this, EXCLUDE_FROM_ALL keeps
# manifoldc out of ALL_BUILD on MSVC — cmake --build --config Release
# (no --target) then exits 0 but never compiles the lib.
add_custom_target(manifold_stack ALL)
add_dependencies(manifold_stack manifoldc)

# No custom shim — manifoldc is manifold's own official C API.
# We just expose its include path so consumers can find manifoldc.h.
# (The D binding generates no C++ code; it binds extern(C) directly.)
