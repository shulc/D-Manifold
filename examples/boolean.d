/// examples/boolean.d — smoke test for D-Manifold static bindings.
///
/// Builds two overlapping cubes, then computes UNION, DIFFERENCE, and
/// INTERSECTION.  For each result it reads back the MeshGL triangle mesh
/// and prints #verts / #tris, then asserts that:
///   • the result is non-empty (has triangles)
///   • manifold_status() == ManifoldError.NoError  (valid 2-manifold)
///   • genus is as expected (closed solid ⇒ genus 0)
///
/// Run:
///   dub run --config=boolean           (triggers preBuildCommands + links)
///
module boolean;

import std.stdio   : writefln, writeln;
import manifold.c;

// Helper: alloc a Manifold, call f(mem) to populate it, return it.
// The returned pointer must be freed with manifold_delete_manifold().
alias ManifoldFactory = ManifoldManifold* function(void*) @nogc nothrow;

void main()
{
    // ----------------------------------------------------------------
    // Build cube A: 2×2×2, centred at origin.
    // Build cube B: 2×2×2, centred at (1, 0, 0)  — offset so they overlap.
    // ----------------------------------------------------------------

    auto cubeA = manifold_alloc_manifold();
    manifold_cube(cubeA, 2.0, 2.0, 2.0, /*center=*/1);
    assert(manifold_status(cubeA) == ManifoldError.NoError,
           "cubeA is not a valid manifold");
    assert(!manifold_is_empty(cubeA), "cubeA must not be empty");

    auto cubeB = manifold_alloc_manifold();
    manifold_cube(cubeB, 2.0, 2.0, 2.0, /*center=*/1);
    manifold_translate(cubeB, cubeB, 1.0, 0.0, 0.0);
    assert(manifold_status(cubeB) == ManifoldError.NoError,
           "cubeB is not a valid manifold");

    writeln("=== D-Manifold boolean example ===");
    writefln("cubeA: %d verts, %d tris",
             manifold_num_vert(cubeA), manifold_num_tri(cubeA));
    writefln("cubeB: %d verts, %d tris",
             manifold_num_vert(cubeB), manifold_num_tri(cubeB));
    writeln();

    // ----------------------------------------------------------------
    // UNION
    // ----------------------------------------------------------------
    auto uni = manifold_alloc_manifold();
    manifold_union(uni, cubeA, cubeB);
    printResult("UNION", uni);
    manifold_delete_manifold(uni);

    // ----------------------------------------------------------------
    // DIFFERENCE  (A minus B)
    // ----------------------------------------------------------------
    auto diff = manifold_alloc_manifold();
    manifold_difference(diff, cubeA, cubeB);
    printResult("DIFFERENCE (A - B)", diff);
    manifold_delete_manifold(diff);

    // ----------------------------------------------------------------
    // INTERSECTION
    // ----------------------------------------------------------------
    auto isec = manifold_alloc_manifold();
    manifold_intersection(isec, cubeA, cubeB);
    printResult("INTERSECTION", isec);
    manifold_delete_manifold(isec);

    // ----------------------------------------------------------------
    // Clean up source cubes
    // ----------------------------------------------------------------
    manifold_delete_manifold(cubeA);
    manifold_delete_manifold(cubeB);

    writeln();
    writeln("OK");
}

void printResult(string label, ManifoldManifold* m) @nogc nothrow
{
    import core.stdc.stdio : printf;

    // Status / topology
    ManifoldError err = manifold_status(m);
    int       empty   = manifold_is_empty(m);
    size_t    nv      = manifold_num_vert(m);
    size_t    nt      = manifold_num_tri(m);
    int       g       = manifold_genus(m);
    double    vol     = manifold_volume(m);
    double    area    = manifold_surface_area(m);

    printf("--- %s ---\n", label.ptr);
    printf("  verts=%zu  tris=%zu  genus=%d  vol=%.4f  area=%.4f\n",
           nv, nt, g, vol, area);
    printf("  status=%d  empty=%d\n", cast(int)err, empty);

    // Assertions (abort on failure in @nogc context)
    assert(err   == ManifoldError.NoError, "boolean result is not a valid 2-manifold");
    assert(!empty, "boolean result must not be empty");
    assert(nt > 0, "must have at least one triangle");
    // Closed solid → genus 0 (Euler characteristic = 2)
    assert(g == 0, "closed solid boolean result must have genus 0");

    // Read back the MeshGL and verify sizes are consistent
    auto gl  = manifold_alloc_meshgl();
    manifold_get_meshgl(gl, m);

    size_t numProp  = manifold_meshgl_num_prop(gl);
    size_t glNv     = manifold_meshgl_num_vert(gl);
    size_t glNt     = manifold_meshgl_num_tri(gl);
    size_t propLen  = manifold_meshgl_vert_properties_length(gl);
    size_t triLen   = manifold_meshgl_tri_length(gl);

    assert(propLen == glNv * numProp, "vert_properties length mismatch");
    assert(triLen  == glNt * 3,       "tri_verts length mismatch");
    assert(glNt == nt, "MeshGL tri count must match manifold_num_tri");

    printf("  meshgl: %zu verts x %zu props, %zu tris — buffers consistent\n",
           glNv, numProp, glNt);

    manifold_delete_meshgl(gl);
}
