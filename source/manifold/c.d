/// D bindings for the Manifold C API (manifoldc).
///
/// Mirrors the official C API from
///   extern/manifold/bindings/c/include/manifold/manifoldc.h  and
///   extern/manifold/bindings/c/include/manifold/types.h
/// exactly — one opaque struct per handle, one extern(C) declaration per
/// entry point. This module covers the boolean-operations subset plus the
/// MeshGL construction / readback lifecycle that vibe3d needs for CSG.
///
/// Memory model
/// ------------
/// Every object has two destruction variants:
///   manifold_destruct_*  — calls the C++ destructor in place (caller keeps
///                          the allocation, e.g. a stack buffer).
///   manifold_delete_*    — destructs AND frees the heap pointer returned
///                          by manifold_alloc_* or any manifold_* factory.
/// Prefer manifold_alloc_* + manifold_delete_* from D (matches the
/// alloc_* / delete_* pattern used in the official Python bindings).
///
/// Usage sketch:
/// -------------
///   import manifold.c;
///
///   // Build a cube Manifold (1×1×1, centred).
///   auto m = manifold_alloc_manifold();
///   manifold_cube(m, 1.0, 1.0, 1.0, 1 /*center*/);
///   scope(exit) manifold_delete_manifold(m);
///
///   // Extract the triangle mesh.
///   auto gl = manifold_alloc_meshgl();
///   manifold_get_meshgl(gl, m);
///   scope(exit) manifold_delete_meshgl(gl);
///   size_t nv = manifold_meshgl_num_vert(gl);   // # unique positions
///   size_t nt = manifold_meshgl_num_tri(gl);    // # triangles
///
module manifold.c;

import core.stdc.stdint : uint32_t, uint64_t, int32_t;
// size_t is a D built-in alias; no import required.

extern (C) @nogc nothrow:

// ---------------------------------------------------------------------------
// Opaque handles (forward-declared structs, matched to types.h)
// ---------------------------------------------------------------------------

struct ManifoldManifold;
struct ManifoldManifoldVec;
struct ManifoldCrossSection;
struct ManifoldCrossSectionVec;
struct ManifoldRayHitVec;
struct ManifoldSimplePolygon;
struct ManifoldPolygons;
struct ManifoldMeshGL;
struct ManifoldMeshGL64;
struct ManifoldBox;
struct ManifoldRect;
struct ManifoldTriangulation;
struct ManifoldExecutionContext;

// ---------------------------------------------------------------------------
// Value types (structs / enums from types.h)
// ---------------------------------------------------------------------------

struct ManifoldManifoldPair {
    ManifoldManifold* first;
    ManifoldManifold* second;
}

struct ManifoldVec2 { double x, y; }
struct ManifoldVec3 { double x, y, z; }
struct ManifoldIVec3 { int x, y, z; }
struct ManifoldVec4 { double x, y, z, w; }

struct ManifoldProperties {
    double surface_area;
    double volume;
}

struct ManifoldRayHit {
    uint64_t   face_id;
    double     distance;
    ManifoldVec3 position;
    ManifoldVec3 normal;
}

/// Boolean operation type.  Maps to ManifoldOpType in types.h.
enum ManifoldOpType : int {
    Add       = 0,  /// Union
    Subtract  = 1,  /// Difference (a minus b)
    Intersect = 2,  /// Intersection
}

/// Status codes returned by manifold_status().
enum ManifoldError : int {
    NoError                    = 0,
    NonFiniteVertex            = 1,
    NotManifold                = 2,
    VertexIndexOutOfBounds     = 3,
    PropertiesWrongLength      = 4,
    MissingPositionProperties  = 5,
    MergeVectorsDifferentLengths = 6,
    MergeIndexOutOfBounds      = 7,
    TransformWrongLength       = 8,
    RunIndexWrongLength        = 9,
    FaceIdWrongLength          = 10,
    InvalidConstruction        = 11,
    ResultTooLarge             = 12,
    InvalidTangents            = 13,
    Cancelled                  = 14,
}

enum ManifoldFillRule : int {
    EvenOdd  = 0,
    NonZero  = 1,
    Positive = 2,
    Negative = 3,
}

// ---------------------------------------------------------------------------
// Sizing helpers — byte size of each type (use with alloca or GC.malloc)
// ---------------------------------------------------------------------------

size_t manifold_manifold_size();
size_t manifold_manifold_vec_size();
size_t manifold_meshgl_size();
size_t manifold_meshgl64_size();
size_t manifold_box_size();
size_t manifold_rect_size();
size_t manifold_simple_polygon_size();
size_t manifold_polygons_size();
size_t manifold_manifold_pair_size();
size_t manifold_cross_section_size();
size_t manifold_cross_section_vec_size();
size_t manifold_ray_hit_vec_size();
size_t manifold_triangulation_size();
size_t manifold_execution_context_size();

// ---------------------------------------------------------------------------
// Heap allocation (manifold_alloc_* + manifold_delete_*)
// ---------------------------------------------------------------------------
// manifold_alloc_* returns a heap-allocated, unconstructed buffer of the
// right size.  Pass it as the `void* mem` (first arg) to any factory that
// writes into caller-provided storage.  After use call manifold_delete_*
// which destructs and frees.

ManifoldManifold*         manifold_alloc_manifold();
ManifoldManifoldVec*      manifold_alloc_manifold_vec();
ManifoldMeshGL*           manifold_alloc_meshgl();
ManifoldMeshGL64*         manifold_alloc_meshgl64();
ManifoldBox*              manifold_alloc_box();
ManifoldRect*             manifold_alloc_rect();
ManifoldSimplePolygon*    manifold_alloc_simple_polygon();
ManifoldPolygons*         manifold_alloc_polygons();
ManifoldCrossSection*     manifold_alloc_cross_section();
ManifoldCrossSectionVec*  manifold_alloc_cross_section_vec();
ManifoldRayHitVec*        manifold_alloc_ray_hit_vec();
ManifoldTriangulation*    manifold_alloc_triangulation();
ManifoldExecutionContext* manifold_alloc_execution_context();

// ---------------------------------------------------------------------------
// In-place destruction (destruct only, caller owns the memory)
// ---------------------------------------------------------------------------

void manifold_destruct_manifold       (ManifoldManifold* m);
void manifold_destruct_manifold_vec   (ManifoldManifoldVec* ms);
void manifold_destruct_meshgl         (ManifoldMeshGL* m);
void manifold_destruct_meshgl64       (ManifoldMeshGL64* m);
void manifold_destruct_box            (ManifoldBox* b);
void manifold_destruct_rect           (ManifoldRect* b);
void manifold_destruct_simple_polygon (ManifoldSimplePolygon* p);
void manifold_destruct_polygons       (ManifoldPolygons* p);
void manifold_destruct_cross_section  (ManifoldCrossSection* m);
void manifold_destruct_cross_section_vec(ManifoldCrossSectionVec* csv);
void manifold_destruct_ray_hit_vec    (ManifoldRayHitVec* v);
void manifold_destruct_triangulation  (ManifoldTriangulation* M);
void manifold_destruct_execution_context(ManifoldExecutionContext* ctx);

// ---------------------------------------------------------------------------
// Delete (destruct + free) — primary lifecycle API from D
// ---------------------------------------------------------------------------

void manifold_delete_manifold         (ManifoldManifold* m);
void manifold_delete_manifold_vec     (ManifoldManifoldVec* ms);
void manifold_delete_meshgl           (ManifoldMeshGL* m);
void manifold_delete_meshgl64         (ManifoldMeshGL64* m);
void manifold_delete_box              (ManifoldBox* b);
void manifold_delete_rect             (ManifoldRect* b);
void manifold_delete_simple_polygon   (ManifoldSimplePolygon* p);
void manifold_delete_polygons         (ManifoldPolygons* p);
void manifold_delete_cross_section    (ManifoldCrossSection* cs);
void manifold_delete_cross_section_vec(ManifoldCrossSectionVec* csv);
void manifold_delete_ray_hit_vec      (ManifoldRayHitVec* v);
void manifold_delete_triangulation    (ManifoldTriangulation* m);
void manifold_delete_execution_context(ManifoldExecutionContext* ctx);

// ---------------------------------------------------------------------------
// MeshGL construction — float precision (32-bit vertex properties)
// ---------------------------------------------------------------------------

/// Construct a MeshGL from caller-supplied arrays.
/// vert_props: flat array, n_verts * n_props floats (first 3 = XYZ).
/// tri_verts:  flat array, n_tris * 3 uint32s (CCW winding).
/// mem:        caller-allocated buffer (manifold_alloc_meshgl() or stack).
ManifoldMeshGL* manifold_meshgl(void* mem,
                                float*    vert_props, size_t n_verts,
                                size_t    n_props,
                                uint32_t* tri_verts,  size_t n_tris);

/// Extract the MeshGL from a Manifold.  Writes into `mem`.
ManifoldMeshGL* manifold_get_meshgl(void* mem, ManifoldManifold* m);

/// Deep copy of a MeshGL.
ManifoldMeshGL* manifold_meshgl_copy(void* mem, ManifoldMeshGL* m);

// ---------------------------------------------------------------------------
// MeshGL accessors
// ---------------------------------------------------------------------------

size_t    manifold_meshgl_num_prop  (ManifoldMeshGL* m);
size_t    manifold_meshgl_num_vert  (ManifoldMeshGL* m);
size_t    manifold_meshgl_num_tri   (ManifoldMeshGL* m);

/// Total length of the vert_properties flat array = num_vert * num_prop.
size_t    manifold_meshgl_vert_properties_length(ManifoldMeshGL* m);
/// Total length of the tri_verts flat array = num_tri * 3.
size_t    manifold_meshgl_tri_length(ManifoldMeshGL* m);

/// Copy the vert_properties float array into `mem`; returns a pointer to it.
float*    manifold_meshgl_vert_properties(void* mem, ManifoldMeshGL* m);
/// Copy the tri_verts uint32 array into `mem`; returns a pointer to it.
uint32_t* manifold_meshgl_tri_verts(void* mem, ManifoldMeshGL* m);

float     manifold_meshgl_tolerance(ManifoldMeshGL* m);

// ---------------------------------------------------------------------------
// Manifold shape factories — write result into caller-allocated `mem`
// ---------------------------------------------------------------------------

/// Empty (zero-triangle) manifold.
ManifoldManifold* manifold_empty(void* mem);

/// Deep copy.
ManifoldManifold* manifold_copy(void* mem, ManifoldManifold* m);

/// Axis-aligned box.  center=1 centres the box at the origin.
ManifoldManifold* manifold_cube(void* mem,
                                double x, double y, double z,
                                int    center);

/// Sphere approximated with `circular_segments` latitudinal bands.
ManifoldManifold* manifold_sphere(void* mem,
                                  double radius,
                                  int    circular_segments);

/// Cylinder / cone (set radius_high=0 for a cone).
ManifoldManifold* manifold_cylinder(void* mem,
                                    double height,
                                    double radius_low,
                                    double radius_high,
                                    int    circular_segments,
                                    int    center);

/// Regular tetrahedron centred at origin, side length = sqrt(8/3).
ManifoldManifold* manifold_tetrahedron(void* mem);

/// Lift a MeshGL into a Manifold (repairs non-manifold geometry if needed).
ManifoldManifold* manifold_of_meshgl(void* mem, ManifoldMeshGL* mesh);

// ---------------------------------------------------------------------------
// Boolean operations
// ---------------------------------------------------------------------------

/// Generic boolean: op selects Add / Subtract / Intersect.
ManifoldManifold* manifold_boolean(void* mem,
                                   ManifoldManifold* a,
                                   ManifoldManifold* b,
                                   ManifoldOpType    op);

/// Convenience wrappers.
ManifoldManifold* manifold_union       (void* mem, ManifoldManifold* a, ManifoldManifold* b);
ManifoldManifold* manifold_difference  (void* mem, ManifoldManifold* a, ManifoldManifold* b);
ManifoldManifold* manifold_intersection(void* mem, ManifoldManifold* a, ManifoldManifold* b);

// ---------------------------------------------------------------------------
// Manifold transformations
// ---------------------------------------------------------------------------

ManifoldManifold* manifold_translate(void* mem, ManifoldManifold* m,
                                     double x, double y, double z);
ManifoldManifold* manifold_scale    (void* mem, ManifoldManifold* m,
                                     double x, double y, double z);
ManifoldManifold* manifold_rotate   (void* mem, ManifoldManifold* m,
                                     double x_deg, double y_deg, double z_deg);

// ---------------------------------------------------------------------------
// Manifold info / status
// ---------------------------------------------------------------------------

/// 1 if the manifold contains no geometry (no triangles), 0 otherwise.
int           manifold_is_empty(ManifoldManifold* m);

/// Returns ManifoldError.NoError (==0) when the geometry is valid.
ManifoldError manifold_status (ManifoldManifold* m);

/// Topology counts.
size_t manifold_num_vert(ManifoldManifold* m);
size_t manifold_num_edge(ManifoldManifold* m);
size_t manifold_num_tri (ManifoldManifold* m);

/// Euler characteristic = V - E + F.  A closed orientable surface has
/// genus g = (2 - χ) / 2, so genus 0 (sphere) ⇒ χ = 2.
int    manifold_genus      (ManifoldManifold* m);
double manifold_surface_area(ManifoldManifold* m);
double manifold_volume      (ManifoldManifold* m);
double manifold_epsilon     (ManifoldManifold* m);

/// Bounding box — writes into `mem`, returns a pointer to it.
ManifoldBox* manifold_bounding_box(void* mem, ManifoldManifold* m);

// ---------------------------------------------------------------------------
// ManifoldBox accessors
// ---------------------------------------------------------------------------

ManifoldVec3 manifold_box_min(ManifoldBox* b);
ManifoldVec3 manifold_box_max(ManifoldBox* b);

// ---------------------------------------------------------------------------
// ManifoldManifoldVec (batch operations)
// ---------------------------------------------------------------------------

ManifoldManifoldVec* manifold_manifold_empty_vec(void* mem);
ManifoldManifoldVec* manifold_manifold_vec      (void* mem, size_t sz);
void                 manifold_manifold_vec_reserve(ManifoldManifoldVec* ms, size_t sz);
size_t               manifold_manifold_vec_length (ManifoldManifoldVec* ms);
ManifoldManifold*    manifold_manifold_vec_get    (void* mem, ManifoldManifoldVec* ms, size_t idx);
void                 manifold_manifold_vec_set    (ManifoldManifoldVec* ms, size_t idx, ManifoldManifold* m);
void                 manifold_manifold_vec_push_back(ManifoldManifoldVec* ms, ManifoldManifold* m);

ManifoldManifold* manifold_batch_boolean(void* mem, ManifoldManifoldVec* ms, ManifoldOpType op);
ManifoldManifold* manifold_compose      (void* mem, ManifoldManifoldVec* ms);
ManifoldManifoldVec* manifold_decompose (void* mem, ManifoldManifold* m);
