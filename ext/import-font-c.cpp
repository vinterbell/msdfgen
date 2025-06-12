
#include "import-font-c.h"
#include <ft2build.h>
#include FT_FREETYPE_H
#include "import-font.h"

extern "C"
{
    msFreetypeHandle *msInitializeFreetype()
    {
        return (msFreetypeHandle *)msdfgen::initializeFreetype();
    }

    void msDeinitializeFreetype(msFreetypeHandle *library)
    {
        msdfgen::deinitializeFreetype((msdfgen::FreetypeHandle *)library);
    }

    /// Creates a FontHandle from FT_Face that was loaded by the user. destroyFont must still be called but will not affect the FT_Face.
    msFontHandle *msAdoptFreetypeFont(FT_Face ftFace)
    {
        return (msFontHandle *)msdfgen::adoptFreetypeFont(ftFace);
    }
    /// Converts the geometry of FreeType's FT_Outline to a Shape object.
    FT_Error msReadFreetypeOutline(msShape *output, FT_Outline *outline, double scale = MSDFGEN_LEGACY_FONT_COORDINATE_SCALE)
    {
        return msdfgen::readFreetypeOutline(*(msdfgen::Shape *)output, outline, scale);
    }

    msFontHandle *msLoadFont(msFreetypeHandle *library, const char *filename)
    {
        return (msFontHandle *)msdfgen::loadFont((msdfgen::FreetypeHandle *)library, filename);
    }

    msFontHandle *msLoadFontData(msFreetypeHandle *library, const uint8_t *data, int length)
    {
        return (msFontHandle *)msdfgen::loadFontData((msdfgen::FreetypeHandle *)library, data, length);
    }

    void msDestroyFont(msFontHandle *font)
    {
        msdfgen::destroyFont((msdfgen::FontHandle *)font);
    }

    bool msGetFontMetrics(msFontMetrics *metrics, msFontHandle *font, msFontCoordinateScaling coordinateScaling)
    {
        return msdfgen::getFontMetrics(*(msdfgen::FontMetrics *)metrics, (msdfgen::FontHandle *)font, (msdfgen::FontCoordinateScaling)coordinateScaling);
    }

    bool msGetFontWhitespaceWidth(double *spaceAdvance, double *tabAdvance, msFontHandle *font, msFontCoordinateScaling coordinateScaling)
    {
        return msdfgen::getFontWhitespaceWidth(*spaceAdvance, *tabAdvance, (msdfgen::FontHandle *)font, (msdfgen::FontCoordinateScaling)coordinateScaling);
    }

    bool msGetGlyphCount(unsigned *output, msFontHandle *font)
    {
        return msdfgen::getGlyphCount(*output, (msdfgen::FontHandle *)font);
    }

    bool msGetGlyphIndex(msGlyphIndex *glyphIndex, msFontHandle *font, unicode_t unicode)
    {
        return msdfgen::getGlyphIndex(*(msdfgen::GlyphIndex *)glyphIndex, (msdfgen::FontHandle *)font, unicode);
    }

    bool msLoadGlyph(msShape *output, msFontHandle *font, unicode_t unicode,
                     msFontCoordinateScaling coordinateScaling = FONT_SCALING_LEGACY,
                     double *outAdvance = nullptr)
    {
        return msdfgen::loadGlyph(*(msdfgen::Shape *)output,
                                  (msdfgen::FontHandle *)font,
                                  unicode,
                                  (msdfgen::FontCoordinateScaling)coordinateScaling,
                                  outAdvance);
    }

    bool msGetKerning(double *output, msFontHandle *font, msGlyphIndex glyphIndex0, msGlyphIndex glyphIndex1, msFontCoordinateScaling coordinateScaling)
    {
        return msdfgen::getKerning(*output, (msdfgen::FontHandle *)font,
                                   *(msdfgen::GlyphIndex *)glyphIndex0,
                                   *(msdfgen::GlyphIndex *)glyphIndex1,
                                   (msdfgen::FontCoordinateScaling)coordinateScaling);
    }
}