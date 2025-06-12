#pragma once
#include "../msdfgen-c.h"
#include "../msdfgen-ext-c.h"
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C"
{
#endif

    typedef uint32_t unicode_t;

    struct msFreetypeHandle;
    typedef struct msFreetypeHandle msFreetypeHandle;
    struct msFontHandle;
    typedef struct msFontHandle msFontHandle;

    typedef unsigned msGlyphIndex;

    /// Global metrics of a typeface (in font units).
    struct msFontMetrics
    {
        /// The size of one EM.
        double emSize;
        /// The vertical position of the ascender and descender relative to the baseline.
        double ascenderY, descenderY;
        /// The vertical difference between consecutive baselines.
        double lineHeight;
        /// The vertical position and thickness of the underline.
        double underlineY, underlineThickness;
    };
    typedef struct msFontMetrics msFontMetrics;

    /// A structure to model a given axis of a variable font.
    struct msFontVariationAxis
    {
        /// The name of the variation axis.
        const char *name;
        /// The axis's minimum coordinate value.
        double minValue;
        /// The axis's maximum coordinate value.
        double maxValue;
        /// The axis's default coordinate value. FreeType computes meaningful default values for Adobe MM fonts.
        double defaultValue;
    };
    typedef struct msFontVariationAxis msFontVariationAxis;

    /// The scaling applied to font glyph coordinates when loading a glyph
    enum msFontCoordinateScaling
    {
        /// The coordinates are kept as the integer values native to the font file
        FONT_SCALING_NONE,
        /// The coordinates will be normalized to the em size, i.e. 1 = 1 em
        FONT_SCALING_EM_NORMALIZED,
        /// The incorrect legacy version that was in effect before version 1.12, coordinate values are divided by 64 - DO NOT USE - for backwards compatibility only
        FONT_SCALING_LEGACY
    };
    typedef enum msFontCoordinateScaling msFontCoordinateScaling;

    /// Initializes the FreeType library.
    msFreetypeHandle *msInitializeFreetype();
    /// Deinitializes the FreeType library.
    void msDeinitializeFreetype(msFreetypeHandle *library);

#ifdef FT_LOAD_DEFAULT // FreeType included
    /// Creates a FontHandle from FT_Face that was loaded by the user. destroyFont must still be called but will not affect the FT_Face.
    msFontHandle *msAdoptFreetypeFont(FT_Face ftFace);
    /// Converts the geometry of FreeType's FT_Outline to a Shape object.
    FT_Error msReadFreetypeOutline(msShape *output, FT_Outline *outline, double scale = MSDFGEN_LEGACY_FONT_COORDINATE_SCALE);
#endif

    /// Loads a font file and returns its handle.
    msFontHandle *msLoadFont(msFreetypeHandle *library, const char *filename);
    /// Loads a font from binary data and returns its handle.
    msFontHandle *msLoadFontData(msFreetypeHandle *library, const uint8_t *data, int length);
    /// Unloads a font.
    void msDestroyFont(msFontHandle *font);
    /// Outputs the metrics of a font.
    bool msGetFontMetrics(msFontMetrics *metrics, msFontHandle *font, msFontCoordinateScaling coordinateScaling);
    /// Outputs the width of the space and tab characters.
    bool msGetFontWhitespaceWidth(double *spaceAdvance, double *tabAdvance, msFontHandle *font, msFontCoordinateScaling coordinateScaling);
    /// Outputs the total number of glyphs available in the font.
    bool msGetGlyphCount(unsigned *output, msFontHandle *font);
    /// Outputs the glyph index corresponding to the specified Unicode character.
    bool msGetGlyphIndex(msGlyphIndex *glyphIndex, msFontHandle *font, unicode_t unicode);
    /// Loads the geometry of a glyph from a font.
    bool msLoadGlyph(msShape *output, msFontHandle *font, unicode_t unicode, msFontCoordinateScaling coordinateScaling, double *outAdvance);

    /// Outputs the kerning distance adjustment between two specific glyphs.
    bool msGetKerning(double *output, msFontHandle *font, msGlyphIndex glyphIndex0, msGlyphIndex glyphIndex1, msFontCoordinateScaling coordinateScaling);

    // #ifndef MSDFGEN_DISABLE_VARIABLE_FONTS
    //     /// Sets a single variation axis of a variable font.
    //     bool msSetFontVariationAxis(msFreetypeHandle *library, msFontHandle *font, const char *name, double coordinate);
    //     /// Lists names and ranges of variation axes of a variable font.
    //     // bool msListFontVariationAxes(std::vector<msFontVariationAxis> &axes, msFreetypeHandle *library, msFontHandle *font);
    // #endif

#ifdef __cplusplus
}
#endif