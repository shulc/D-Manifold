# D-Manifold

D bindings for **[elalish/manifold](https://github.com/elalish/manifold)** — robust mesh boolean
operations (CSG: union, difference, intersection) via manifold's official C API (`manifoldc`).
Static linking — no runtime shared-library dependency on libmanifold or libClipper2.

## Layout

```
source/manifold/c.d            — D extern(C) bindings, 1-to-1 with manifoldc.h / types.h
CMakeLists.txt                 — builds extern/manifold statically (manifoldc + manifold + Clipper2)
extern/manifold                — git submodule, pinned to v3.5.2 (commit 11235e6b)
examples/boolean.d             — smoke test: union + difference + intersection of two cubes
dub.json                       — preBuildCommands + lflags wiring for static link
```

## Pinned upstream

| Tag    | Commit      |
|--------|-------------|
| v3.5.2 | `11235e6b8ebea2dbed8aec4285685aafd3d95667` |

Verify after clone:
```sh
git -C extern/manifold describe --tags --exact-match HEAD
# → v3.5.2
```

## First build

```sh
git submodule update --init --recursive
dub build                   # library configuration (staticLibrary)
dub run --config=boolean    # build + run the boolean example
```

`preBuildCommands-posix` in `dub.json` runs CMake on the submodule before the D
compilation step, so a plain `dub build` is enough.

Static libraries produced by CMake and linked into the example:

| Library | Location under `build/` |
|---------|--------------------------|
| `libmanifoldc.a` | `extern/manifold/bindings/c/libmanifoldc.a` |
| `libmanifold.a` | `extern/manifold/src/libmanifold.a` |
| `libClipper2.a` | `_deps/clipper2-build/libClipper2.a` |

## Boolean example output

```
=== D-Manifold boolean example ===
cubeA: 8 verts, 12 tris
cubeB: 8 verts, 12 tris

--- UNION ---
  verts=...  tris=...  genus=0  vol=...  area=...
  status=0  empty=0
  meshgl: ... verts x 3 props, ... tris — buffers consistent
--- DIFFERENCE (A - B) ---
  ...
--- INTERSECTION ---
  ...

OK
```

`status=0` = `ManifoldError.NoError`.  `genus=0` confirms closed orientable solid
(Euler characteristic 2 → genus 0 for each boolean result).

## Static-link verification

After `dub run --config=boolean` the `boolean` executable must have no manifold or
Clipper2 shared-object dependencies:

```sh
ldd boolean | grep -E 'manifold|Clipper'
# (no output — confirmed pure static)
```

## Consuming from another dub project

```json
"dependencies": {
    "d-manifold": { "path": "../D-Manifold" }
}
```

Then `import manifold.c;`.  dub resolves the dependency through the `library`
configuration (staticLibrary), invoking CMake via `preBuildCommands` before
compiling your project.

## Binding scope

This module covers the **boolean / CSG** subset of the C API:

- **MeshGL construction**: `manifold_meshgl` (from raw float/uint32 arrays)
- **Shape factories**: `manifold_cube`, `manifold_sphere`, `manifold_cylinder`,
  `manifold_tetrahedron`, `manifold_of_meshgl`
- **Boolean operations**: `manifold_union`, `manifold_difference`,
  `manifold_intersection`, `manifold_boolean` (generic), `manifold_batch_boolean`
- **Transformations**: `manifold_translate`, `manifold_scale`, `manifold_rotate`
- **Result readback**: `manifold_get_meshgl`, `manifold_meshgl_num_vert`,
  `manifold_meshgl_num_tri`, `manifold_meshgl_vert_properties`,
  `manifold_meshgl_tri_verts`
- **Status / info**: `manifold_status`, `manifold_is_empty`, `manifold_num_vert`,
  `manifold_num_tri`, `manifold_genus`, `manifold_volume`, `manifold_surface_area`
- **Lifecycle**: `manifold_alloc_*`, `manifold_destruct_*`, `manifold_delete_*`
  for all handle types; sizing helpers `manifold_*_size()`

The 2D / CrossSection API, SDF level-set, smooth/refine, ray-casting,
ExecutionContext, and MeshGL64 (double-precision) are declared as opaque types
and can be added as needed.

## CMake cache variables set

| Variable | Value | Reason |
|----------|-------|--------|
| `MANIFOLD_TEST` | OFF | skip test suite build |
| `MANIFOLD_PYBIND` | OFF | no Python bindings |
| `MANIFOLD_JSBIND` | OFF | no JS/Emscripten bindings |
| `MANIFOLD_PAR` | OFF | no TBB parallel backend |
| `MANIFOLD_DEBUG` | OFF | no debug tracing |
| `MANIFOLD_CROSS_SECTION` | ON | required for C bindings (manifoldc depends on it) |
| `MANIFOLD_CBIND` | ON | builds the `manifoldc` target |
| `BUILD_SHARED_LIBS` | OFF | static link |
| `MANIFOLD_DOWNLOADS` | ON | FetchContent for Clipper2 (no system Clipper2 cmake) |

`install()` is shadowed with a no-op during `add_subdirectory(extern/manifold)`
to avoid empty-export errors from CMake's generate step — same technique used by
D-OpenSubdiv for Pixar OpenSubdiv.

## License

The D bindings (`source/`, `CMakeLists.txt`, `examples/`) are
**Apache-2.0**, matching the upstream manifold license.

manifold itself is © The Manifold Authors, Apache-2.0.
Clipper2 is © Angus Johnson, Boost Software License 1.0.
