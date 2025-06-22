#pragma once

#include <stdlib.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif
    //
    struct msFontHandle
    {
        void *font; // Pointer to the font handle, implementation-specific (FT_Face for FreeType, etc.)
        bool owned; // Indicates if the font handle is owned by this structure (true if it should be destroyed with msFontHandleDestroy)
    };
    typedef struct msFontHandle msFontHandle;

    struct msaCharset;
    typedef struct msaCharset msaCharset;

    msaCharset *msaCharsetCreate(void);
    msaCharset *msaCharsetASCII(void);
    void msaCharsetDestroy(msaCharset *charset);
    void msaCharsetAdd(msaCharset *charset, uint32_t cp);
    void msaCharsetRemove(msaCharset *charset, uint32_t cp);
    size_t msaCharsetSize(const msaCharset *charset);

    // operations on glyphs in an array
    typedef struct msaGlyphGeometry msaGlyphGeometry;
    struct msaGlyphRange
    {
        msaGlyphGeometry *firstGlyph; // Pointer to the first glyph in the range
        size_t glyphCount;            // Number of glyphs in the range
    };
    typedef struct msaGlyphRange msaGlyphRange;
    // TODO rest of the GlyphGeometry API

    enum msaEdgeColoringFunction
    {
        EDGE_COLORING_SIMPLE = 0,
        EDGE_COLORING_INK_TRAP = 1,
        EDGE_COLORING_BY_DISTANCE = 2,
    };
    typedef enum msaEdgeColoringFunction msaEdgeColoringFunction;
    void msaGlyphRangeSetEdgeColoring(
        msaGlyphRange range,
        size_t index,
        msaEdgeColoringFunction fn,
        double angleThreshold,
        unsigned long long seed);
    float msaGlyphRangeGetAdvance(
        const msaGlyphRange range,
        size_t index);
    void msaGlyphRangeGetBoxRect(
        msaGlyphRange range,
        size_t index,
        int *x, int *y, int *w, int *h);
    void msaGlyphRangeGetQuadPlaneBounds(
        const msaGlyphRange range,
        size_t index,
        double *l, double *b, double *r, double *t);
    size_t msaGlyphRangeGetGlyphIndex(
        const msaGlyphRange range,
        size_t index);
    uint32_t msaGlyphRangeGetCodepoint(
        const msaGlyphRange range,
        size_t index);

    // TODO rest of the GlyphGeometry API

    // struct GlyphAttributes {
    //     double scale;
    //     msdfgen::Range range;
    //     Padding innerPadding, outerPadding;
    //     double miterLimit;
    //     bool pxAlignOriginX, pxAlignOriginY;
    // };

    // GlyphGeometry();
    // /// Loads glyph geometry from font
    // bool load(msdfgen::FontHandle *font, double geometryScale, msdfgen::GlyphIndex index, bool preprocessGeometry = true);
    // bool load(msdfgen::FontHandle *font, double geometryScale, uint32_t codepoint, bool preprocessGeometry = true);
    // /// Applies edge coloring to glyph shape
    // void edgeColoring(void (*fn)(msdfgen::Shape &, double, unsigned long long), double angleThreshold, unsigned long long seed);
    // /// Computes the dimensions of the glyph's box as well as the transformation for the generator function
    // void wrapBox(const GlyphAttributes &glyphAttributes);
    // void wrapBox(double scale, double range, double miterLimit, bool pxAlignOrigin = false);
    // void wrapBox(double scale, double range, double miterLimit, bool pxAlignOriginX, bool pxAlignOriginY);
    // /// Computes the glyph's transformation and alignment (unless specified) for given dimensions
    // void frameBox(const GlyphAttributes &glyphAttributes, int width, int height, const double *fixedX, const double *fixedY);
    // void frameBox(double scale, double range, double miterLimit, int width, int height, const double *fixedX, const double *fixedY, bool pxAlignOrigin = false);
    // void frameBox(double scale, double range, double miterLimit, int width, int height, const double *fixedX, const double *fixedY, bool pxAlignOriginX, bool pxAlignOriginY);
    // /// Sets the glyph's box's position in the atlas
    // void placeBox(int x, int y);
    // /// Sets the glyph's box's rectangle in the atlas
    // void setBoxRect(const Rectangle &rect);
    // /// Returns the glyph's index within the font
    // int getIndex() const;
    // /// Returns the glyph's index as a msdfgen::GlyphIndex
    // msdfgen::GlyphIndex getGlyphIndex() const;
    // /// Returns the Unicode codepoint represented by the glyph or 0 if unknown
    // uint32_t getCodepoint() const;
    // /// Returns the glyph's identifier specified by the supplied identifier type
    // int getIdentifier(GlyphIdentifierType type) const;
    // /// Returns the glyph's geometry scale
    // double getGeometryScale() const;
    // /// Returns the glyph's shape
    // const msdfgen::Shape &getShape() const;
    // /// Returns the glyph's shape's raw bounds
    // const msdfgen::Shape::Bounds &getShapeBounds() const;
    // /// Returns the glyph's advance
    // double getAdvance() const;
    // /// Returns the glyph's box in the atlas
    // Rectangle getBoxRect() const;
    // /// Outputs the position and dimensions of the glyph's box in the atlas
    // void getBoxRect(int &x, int &y, int &w, int &h) const;
    // /// Outputs the dimensions of the glyph's box in the atlas
    // void getBoxSize(int &w, int &h) const;
    // /// Returns the range needed to generate the glyph's SDF
    // msdfgen::Range getBoxRange() const;
    // /// Returns the projection needed to generate the glyph's bitmap
    // msdfgen::Projection getBoxProjection() const;
    // /// Returns the scale needed to generate the glyph's bitmap
    // double getBoxScale() const;
    // /// Returns the translation vector needed to generate the glyph's bitmap
    // msdfgen::Vector2 getBoxTranslate() const;
    // /// Outputs the bounding box of the glyph as it should be placed on the baseline
    // void getQuadPlaneBounds(double &l, double &b, double &r, double &t) const;
    // /// Outputs the bounding box of the glyph in the atlas
    // void getQuadAtlasBounds(double &l, double &b, double &r, double &t) const;
    // /// Returns true if the glyph is a whitespace and has no geometry
    // bool isWhitespace() const;
    // /// Simplifies to GlyphBox
    // operator GlyphBox() const;

    struct msaFontGeometry;
    typedef struct msaFontGeometry msaFontGeometry;

    msaFontGeometry *msaFontGeometryCreate(void);
    void msaFontGeometryDestroy(msaFontGeometry *fontGeometry);
    // returns number of loaded glyphs
    int msaFontGeometryLoadCharset(
        msaFontGeometry *fontGeometry,
        msFontHandle *font,
        double fontScale,
        const msaCharset *charset);
    msaGlyphRange msaFontGeometryGetGlyphs(const msaFontGeometry *fontGeometry);

    struct msaPacker;
    typedef struct msaPacker msaPacker;

    enum msaDimensionsConstraint
    {
        DIMENSION_CONSTRAINT_NONE = 0,
        DIMENSION_CONSTRAINT_SQUARE,
        DIMENSION_CONSTRAINT_EVEN_SQUARE,
        DIMENSION_CONSTRAINT_MULTIPLE_OF_FOUR_SQUARE,
        DIMENSION_CONSTRAINT_POWER_OF_TWO_RECTANGLE,
        DIMENSION_CONSTRAINT_POWER_OF_TWO_SQUARE
    };
    typedef enum msaDimensionsConstraint msaDimensionsConstraint;

    msaPacker *msaPackerCreate(void);
    void msaPackerDestroy(msaPacker *packer);
    /// returns 0 on success
    int msaPackerPack(msaPacker *packer, msaGlyphRange range);
    void msaPackerSetDimensions(msaPacker *packer, int width, int height);
    void msaPackerUnsetDimensions(msaPacker *packer);
    void msaPackerSetDimensionsConstraint(msaPacker *packer, msaDimensionsConstraint dimensionsConstraint);
    void msaPackerSetSpacing(msaPacker *packer, int spacing);
    void msaPackerSetScale(msaPacker *packer, double scale);
    void msaPackerSetMinimumScale(msaPacker *packer, double minScale);
    void msaPackerSetUnitRange(msaPacker *packer, double unitLower, double unitUpper);
    void msaPackerSetPixelRange(msaPacker *packer, double pxLower, double pxUpper);
    void msaPackerSetMiterLimit(msaPacker *packer, double miterLimit);
    void msaPackerSetOriginPixelAlignment(msaPacker *packer, bool align);
    void msaPackerSetOriginPixelAlignmentXY(msaPacker *packer, bool alignX, bool alignY);
    void msaPackerSetInnerUnitPadding(msaPacker *packer, double l, double b, double r, double t);
    void msaPackerSetOuterUnitPadding(msaPacker *packer, double l, double b, double r, double t);
    void msaPackerSetInnerPixelPadding(msaPacker *packer, double l, double b, double r, double t);
    void msaPackerSetOuterPixelPadding(msaPacker *packer, double l, double b, double r, double t);
    void msaPackerGetDimensions(const msaPacker *packer, int *width, int *height);
    double msaPackerGetScale(const msaPacker *packer);
    void msaPackerGetPixelRange(const msaPacker *packer, double *pxLower, double *pxUpper);

    struct msaImmediateAtlasGenerator;
    typedef struct msaImmediateAtlasGenerator msaImmediateAtlasGenerator;
    msaImmediateAtlasGenerator *msaImmediateAtlasGeneratorCreate(uint32_t width, uint32_t height);
    void msaImmediateAtlasGeneratorDestroy(msaImmediateAtlasGenerator *generator);
    void msaImmediateAtlasGeneratorSetThreadCount(msaImmediateAtlasGenerator *generator, int threadCount);
    void msaImmediateAtlasGeneratorGenerate(msaImmediateAtlasGenerator *generator, msaGlyphRange range);
    /// 3x f32 for each pixel in the atlas
    float *msaImmediateAtlasGeneratorGetBitmap(msaImmediateAtlasGenerator *generator, int *width, int *height);

    typedef enum msaAtlasChangeFlags
    {
        NO_CHANGE = 0x00,
        RESIZED = 0x01,
        REARRANGED = 0x02
    } msaAtlasChangeFlags;

    struct msaDynamicAtlasGenerator;
    typedef struct msaDynamicAtlasGenerator msaDynamicAtlasGenerator;
    msaDynamicAtlasGenerator *msaDynamicAtlasGeneratorCreate(void);
    void msaDynamicAtlasGeneratorDestroy(msaDynamicAtlasGenerator *generator);
    msaAtlasChangeFlags msaDynamicAtlasGeneratorAddGlyphs(
        msaDynamicAtlasGenerator *generator,
        const msaGlyphRange range);

#ifdef __cplusplus
}
#endif