#pragma once

#include <stdlib.h>

#ifdef __cplusplus
extern "C"
{
#endif

    extern void *msdfgen_malloc(size_t size);
    extern void msdfgen_free(void *ptr);

    struct msContour;
    struct msShape;
    typedef struct msContour msContour;
    typedef struct msShape msShape;

    msShape *msShapeCreate(void);
    void msShapeDestroy(msShape *shape);
    msContour *msShapeAddContour(msShape *shape);
    void msShapeNormalize(msShape *cShape);
    void msShapeOrientContours(msShape *cShape);
    void msEdgeColoringSimple(msShape *cShape, double angleThreshold, unsigned long long seed);
    void msContourAddLinearEdge(msContour *cContour, double x1, double y1, double x2, double y2);
    void msContourAddQuadraticEdge(msContour *cContour, double x1, double y1, double x2, double y2, double x3, double y3);
    void msContourAddCubicEdge(msContour *cContour, double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4);
    void msGenerateSDF(float *data, int w, int h, msShape *shape, double range, double sx, double sy, double dx, double dy);
    void msGeneratePseudoSDF(float *data, int w, int h, msShape *shape, double range, double sx, double sy, double dx, double dy);
    void msGenerateMSDF(float *data, int w, int h, msShape *shape, double range, double sx, double sy, double dx, double dy);
    void msGenerateMTSDF(float *data, int w, int h, msShape *shape, double range, double sx, double sy, double dx, double dy);

#ifdef __cplusplus
}
#endif