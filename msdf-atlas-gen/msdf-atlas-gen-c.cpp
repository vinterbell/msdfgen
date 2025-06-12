#include "msdf-atlas-gen-c.h"

#include "msdf-atlas-gen.h"

using namespace msdf_atlas;

extern "C"
{
    // charset
    msaCharset *msaCharsetCreate(void)
    {
        return (msaCharset *)new Charset();
    }

    msaCharset *msaCharsetASCII(void)
    {
        Charset *ascii = new Charset();
        for (unicode_t cp = 0x20; cp < 0x7f; ++cp)
            ascii->add(cp);
        return (msaCharset *)ascii;
    }

    void msaCharsetDestroy(msaCharset *charset)
    {
        delete (Charset *)charset;
    }

    void msaCharsetAdd(msaCharset *charset, uint32_t cp)
    {
        ((Charset *)charset)->add(cp);
    }

    void msaCharsetRemove(msaCharset *charset, uint32_t cp)
    {
        ((Charset *)charset)->remove(cp);
    }

    size_t msaCharsetSize(const msaCharset *charset)
    {
        return ((const Charset *)charset)->size();
    }

    // glyph geometry
    void msaGlyphRangeSetEdgeColoring(
        msaGlyphRange range,
        size_t index,
        msaEdgeColoringFunction fn,
        double angleThreshold,
        unsigned long long seed)
    {
        GlyphGeometry *glyph = (GlyphGeometry *)range.firstGlyph + index;
        switch (fn)
        {
        case EDGE_COLORING_INK_TRAP:
            glyph->edgeColoring(msdfgen::edgeColoringInkTrap, angleThreshold, seed);
            break;
        case EDGE_COLORING_BY_DISTANCE:
            glyph->edgeColoring(msdfgen::edgeColoringByDistance, angleThreshold, seed);
            break;
        case EDGE_COLORING_SIMPLE:
            glyph->edgeColoring(msdfgen::edgeColoringSimple, angleThreshold, seed);
            break;
        }
    }

    float msaGlyphRangeGetAdvance(
        const msaGlyphRange range,
        size_t index)
    {
        const GlyphGeometry *glyph = (const GlyphGeometry *)range.firstGlyph + index;
        return glyph->getAdvance();
    }

    void msaGlyphRangeGetBoxRect(
        msaGlyphRange range,
        size_t index,
        int *x, int *y, int *w, int *h)
    {
        GlyphGeometry *glyph = (GlyphGeometry *)range.firstGlyph + index;
        glyph->getBoxRect(*x, *y, *w, *h);
    }

    void msaGlyphRangeGetQuadPlaneBounds(
        const msaGlyphRange range,
        size_t index,
        double *l, double *b, double *r, double *t)
    {
        const GlyphGeometry *glyph = (const GlyphGeometry *)range.firstGlyph + index;
        glyph->getQuadPlaneBounds(*l, *b, *r, *t);
    }

    size_t msaGlyphRangeGetGlyphIndex(
        const msaGlyphRange range,
        size_t index)
    {
        const GlyphGeometry *glyph = (const GlyphGeometry *)range.firstGlyph + index;
        return glyph->getGlyphIndex().getIndex();
    }

    uint32_t msaGlyphRangeGetCodepoint(
        const msaGlyphRange range,
        size_t index)
    {
        const GlyphGeometry *glyph = (const GlyphGeometry *)range.firstGlyph + index;
        return glyph->getCodepoint();
    }

    // font geometry
    msaFontGeometry *msaFontGeometryCreate(void)
    {
        return (msaFontGeometry *)new FontGeometry();
    }
    void msaFontGeometryDestroy(msaFontGeometry *fontGeometry)
    {
        delete (FontGeometry *)fontGeometry;
    }

    int msaFontGeometryLoadCharset(
        msaFontGeometry *fontGeometry,
        msFontHandle *font,
        double fontScale,
        const msaCharset *charset)
    {
        return ((FontGeometry *)fontGeometry)->loadCharset((msdfgen::FontHandle *)font, fontScale, *(const Charset *)charset);
    }

    msaGlyphRange msaFontGeometryGetGlyphs(const msaFontGeometry *fontGeometry)
    {
        const FontGeometry *fg = (const FontGeometry *)fontGeometry;
        msaGlyphRange range;
        const FontGeometry::GlyphRange originalRange = fg->getGlyphs();
        range.firstGlyph = (msaGlyphGeometry *)originalRange.begin();
        range.glyphCount = originalRange.size();
        return range;
    }

    // packer
    msaPacker *msaPackerCreate(void)
    {
        return (msaPacker *)new TightAtlasPacker();
    }
    void msaPackerDestroy(msaPacker *packer)
    {
        delete (TightAtlasPacker *)packer;
    }
    /// returns 0 on success
    int msaPackerPack(msaPacker *packer, msaGlyphRange range)
    {
        return ((TightAtlasPacker *)packer)->pack((GlyphGeometry *)range.firstGlyph, (int)range.glyphCount);
    }
    void msaPackerSetDimensions(msaPacker *packer, int width, int height)
    {
        ((TightAtlasPacker *)packer)->setDimensions(width, height);
    }
    void msaPackerUnsetDimensions(msaPacker *packer)
    {
        ((TightAtlasPacker *)packer)->unsetDimensions();
    }
    void msaPackerSetDimensionsConstraint(msaPacker *packer, msaDimensionsConstraint dimensionsConstraint)
    {
        ((TightAtlasPacker *)packer)->setDimensionsConstraint((DimensionsConstraint)dimensionsConstraint);
    }
    void msaPackerSetSpacing(msaPacker *packer, int spacing)
    {
        ((TightAtlasPacker *)packer)->setSpacing(spacing);
    }
    void msaPackerSetScale(msaPacker *packer, double scale)
    {
        ((TightAtlasPacker *)packer)->setScale(scale);
    }
    void msaPackerSetMinimumScale(msaPacker *packer, double minScale)
    {
        ((TightAtlasPacker *)packer)->setMinimumScale(minScale);
    }
    void msaPackerSetUnitRange(msaPacker *packer, double unitLower, double unitUpper)
    {
        ((TightAtlasPacker *)packer)->setUnitRange(msdfgen::Range(unitLower, unitUpper));
    }
    void msaPackerSetPixelRange(msaPacker *packer, double pxLower, double pxUpper)
    {
        ((TightAtlasPacker *)packer)->setPixelRange(msdfgen::Range(pxLower, pxUpper));
    }
    void msaPackerSetMiterLimit(msaPacker *packer, double miterLimit)
    {
        ((TightAtlasPacker *)packer)->setMiterLimit(miterLimit);
    }
    void msaPackerSetOriginPixelAlignment(msaPacker *packer, bool align)
    {
        ((TightAtlasPacker *)packer)->setOriginPixelAlignment(align);
    }
    void msaPackerSetOriginPixelAlignmentXY(msaPacker *packer, bool alignX, bool alignY)
    {
        ((TightAtlasPacker *)packer)->setOriginPixelAlignment(alignX, alignY);
    }
    void msaPackerSetInnerUnitPadding(msaPacker *packer, double l, double b, double r, double t)
    {
        ((TightAtlasPacker *)packer)->setInnerUnitPadding(Padding(l, b, r, t));
    }
    void msaPackerSetOuterUnitPadding(msaPacker *packer, double l, double b, double r, double t)
    {
        ((TightAtlasPacker *)packer)->setOuterUnitPadding(Padding(l, b, r, t));
    }
    void msaPackerSetInnerPixelPadding(msaPacker *packer, double l, double b, double r, double t)
    {
        ((TightAtlasPacker *)packer)->setInnerPixelPadding(Padding(l, b, r, t));
    }
    void msaPackerSetOuterPixelPadding(msaPacker *packer, double l, double b, double r, double t)
    {
        ((TightAtlasPacker *)packer)->setOuterPixelPadding(Padding(l, b, r, t));
    }
    void msaPackerGetDimensions(const msaPacker *packer, int *width, int *height)
    {
        ((const TightAtlasPacker *)packer)->getDimensions(*width, *height);
    }
    double msaPackerGetScale(const msaPacker *packer)
    {
        return ((const TightAtlasPacker *)packer)->getScale();
    }
    void msaPackerGetPixelRange(const msaPacker *packer, double *pxLower, double *pxUpper)
    {
        msdfgen::Range range = ((const TightAtlasPacker *)packer)->getPixelRange();
        *pxLower = range.lower;
        *pxUpper = range.upper;
    }

    using ImmediateAtGen = ImmediateAtlasGenerator<float, 3, msdfGenerator, BitmapAtlasStorage<float, 3>>;

    // immediate atlas generator
    msaImmediateAtlasGenerator *msaImmediateAtlasGeneratorCreate(uint32_t width, uint32_t height)
    {
        return (msaImmediateAtlasGenerator *)new ImmediateAtGen(width, height);
    }
    void msaImmediateAtlasGeneratorDestroy(msaImmediateAtlasGenerator *generator)
    {
        ImmediateAtGen *gen = (ImmediateAtGen *)generator;
        delete gen;
    }
    void msaImmediateAtlasGeneratorSetThreadCount(msaImmediateAtlasGenerator *generator, int threadCount)
    {
        ImmediateAtGen *gen = (ImmediateAtGen *)generator;
        gen->setThreadCount(threadCount);
    }
    void msaImmediateAtlasGeneratorGenerate(msaImmediateAtlasGenerator *generator, msaGlyphRange range)
    {
        ImmediateAtGen *gen = (ImmediateAtGen *)generator;
        gen->generate((GlyphGeometry *)range.firstGlyph, (int)range.glyphCount);
    }
    float *msaImmediateAtlasGeneratorGetBitmap(msaImmediateAtlasGenerator *generator, int *width, int *height)
    {
        ImmediateAtGen *gen = (ImmediateAtGen *)generator;
        const msdfgen::BitmapConstRef<float, 3> &storage = gen->atlasStorage();
        *width = storage.width;
        *height = storage.height;
        return (float *)storage.pixels;
    }
}