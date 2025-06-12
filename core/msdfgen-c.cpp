#include "../msdfgen-c.h"
#include "../msdfgen.h"
#include "Shape.h"
#include "Bitmap.h"

using namespace msdfgen;

#ifdef __cplusplus
extern "C"
{
#endif

  MSDFGEN_PUBLIC msShape *msShapeCreate()
  {
    Shape *shape = new Shape;
    return reinterpret_cast<msShape *>(shape);
  }

  MSDFGEN_PUBLIC void msShapeDestroy(msShape *cShape)
  {
    delete reinterpret_cast<Shape *>(cShape);
  }

  MSDFGEN_PUBLIC msContour *msShapeAddContour(msShape *cShape)
  {
    Shape *shape = reinterpret_cast<Shape *>(cShape);
    return reinterpret_cast<msContour *>(&shape->addContour());
  }

  MSDFGEN_PUBLIC void msShapeNormalize(msShape *cShape)
  {
    reinterpret_cast<Shape *>(cShape)->normalize();
  }

  MSDFGEN_PUBLIC void msShapeOrientContours(msShape *cShape)
  {
    reinterpret_cast<Shape *>(cShape)->orientContours();
  }

  MSDFGEN_PUBLIC void msEdgeColoringSimple(msShape *cShape, double angleThreshold, unsigned long long seed)
  {
    Shape *shape = reinterpret_cast<Shape *>(cShape);
    edgeColoringSimple(*shape, angleThreshold, seed);
  }

  MSDFGEN_PUBLIC void msContourAddLinearEdge(msContour *cContour, double x1, double y1, double x2, double y2)
  {
    Contour *contour = reinterpret_cast<Contour *>(cContour);
    Point2 p0(x1, y1);
    Point2 p1(x2, y2);
    contour->addEdge(new LinearSegment(p0, p1));
  }

  MSDFGEN_PUBLIC void msContourAddQuadraticEdge(msContour *cContour, double x1, double y1, double x2, double y2, double x3, double y3)
  {
    Contour *contour = reinterpret_cast<Contour *>(cContour);
    Point2 p0(x1, y1);
    Point2 p1(x2, y2);
    Point2 p2(x3, y3);
    contour->addEdge(new QuadraticSegment(p0, p1, p2));
  }

  MSDFGEN_PUBLIC void msContourAddCubicEdge(msContour *cContour, double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4)
  {
    Contour *contour = reinterpret_cast<Contour *>(cContour);
    Point2 p0(x1, y1);
    Point2 p1(x2, y2);
    Point2 p2(x3, y3);
    Point2 p3(x4, y4);
    contour->addEdge(new CubicSegment(p0, p1, p2, p3));
  }

  MSDFGEN_PUBLIC void msGenerateSDF(float *data, int w, int h, msShape *cShape, double range, double sx, double sy, double dx, double dy)
  {
    Shape *shape = reinterpret_cast<Shape *>(cShape);
    const BitmapRef<float, 1> bitmap(data, w, h);
    generateSDF(bitmap, *shape, range, Vector2(sx, sy), Vector2(dx, dy));
  }

  MSDFGEN_PUBLIC void msGeneratePseudoSDF(float *data, int w, int h, msShape *cShape, double range, double sx, double sy, double dx, double dy)
  {
    Shape *shape = reinterpret_cast<Shape *>(cShape);
    const BitmapRef<float, 1> bitmap(data, w, h);
    generatePseudoSDF(bitmap, *shape, range, Vector2(sx, sy), Vector2(dx, dy));
  }

  MSDFGEN_PUBLIC void msGenerateMSDF(float *data, int w, int h, msShape *cShape, double range, double sx, double sy, double dx, double dy)
  {
    Shape *shape = reinterpret_cast<Shape *>(cShape);
    const BitmapRef<float, 3> bitmap(data, w, h);
    generateMSDF(bitmap, *shape, range, Vector2(sx, sy), Vector2(dx, dy));
  }

  MSDFGEN_PUBLIC void msGenerateMTSDF(float *data, int w, int h, msShape *cShape, double range, double sx, double sy, double dx, double dy)
  {
    Shape *shape = reinterpret_cast<Shape *>(cShape);
    const BitmapRef<float, 4> bitmap(data, w, h);
    generateMTSDF(bitmap, *shape, range, Vector2(sx, sy), Vector2(dx, dy));
  }

#ifdef __cplusplus
}
#endif

// void* operator new(size_t size) {
//   return msdfgen_malloc(size);
// }

// void operator delete(void* ptr) noexcept {
//   msdfgen_free(ptr);
// }