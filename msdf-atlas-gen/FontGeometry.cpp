
#include "FontGeometry.h"

#define DEFAULT_FONT_UNITS_PER_EM 2048.0

namespace msdf_atlas {

FontGeometry::GlyphRange::GlyphRange() : glyphs(), rangeStart(), rangeEnd() { }

FontGeometry::GlyphRange::GlyphRange(const std::vector<GlyphGeometry, Allocator<GlyphGeometry>> *glyphs, size_t rangeStart, size_t rangeEnd) : glyphs(glyphs), rangeStart(rangeStart), rangeEnd(rangeEnd) { }

size_t FontGeometry::GlyphRange::size() const {
    return glyphs->size();
}

bool FontGeometry::GlyphRange::empty() const {
    return glyphs->empty();
}

const GlyphGeometry *FontGeometry::GlyphRange::begin() const {
    return glyphs->data()+rangeStart;
}

const GlyphGeometry *FontGeometry::GlyphRange::end() const {
    return glyphs->data()+rangeEnd;
}

FontGeometry::FontGeometry() : geometryScale(1), metrics(), preferredIdentifierType(GlyphIdentifierType::UNICODE_CODEPOINT), glyphs(&ownGlyphs), rangeStart(0), rangeEnd(0) { }

FontGeometry::FontGeometry(std::vector<GlyphGeometry, Allocator<GlyphGeometry>> *glyphStorage) : geometryScale(1), metrics(), preferredIdentifierType(GlyphIdentifierType::UNICODE_CODEPOINT) {
    glyphs = glyphStorage ? glyphStorage : &ownGlyphs;
    rangeStart = glyphs->size();
    rangeEnd = glyphs->size();
}

FontGeometry::FontGeometry(FontGeometry &&orig) : geometryScale(orig.geometryScale), metrics(orig.metrics), preferredIdentifierType(orig.preferredIdentifierType), glyphs(orig.glyphs), rangeStart(orig.rangeStart), rangeEnd(orig.rangeEnd), glyphsByIndex(std::move(orig.glyphsByIndex)), glyphsByCodepoint(std::move(orig.glyphsByCodepoint)), kerning(std::move(orig.kerning)), ownGlyphs(std::move(orig.ownGlyphs)), name(std::move(orig.name)) {
    if (glyphs == &orig.ownGlyphs)
        glyphs = &ownGlyphs;
}

FontGeometry &FontGeometry::operator=(FontGeometry &&orig) {
    if (this != &orig) {
        geometryScale = orig.geometryScale;
        metrics = orig.metrics;
        glyphs = orig.glyphs == &orig.ownGlyphs ? &ownGlyphs : orig.glyphs;
        rangeStart = orig.rangeStart;
        rangeEnd = orig.rangeEnd;
        glyphsByIndex = std::move(orig.glyphsByIndex);
        glyphsByCodepoint = std::move(orig.glyphsByCodepoint);
        kerning = std::move(orig.kerning);
        ownGlyphs = std::move(orig.ownGlyphs);
        name = std::move(orig.name);
    }
    return *this;
}

int FontGeometry::loadGlyphRange(msdfgen::FontHandle *font, double fontScale, unsigned rangeStart, unsigned rangeEnd, bool preprocessGeometry, bool enableKerning) {
    if (!(glyphs->size() == this->rangeEnd && loadMetrics(font, fontScale)))
        return -1;
    glyphs->reserve(glyphs->size()+(rangeEnd-rangeStart));
    int loaded = 0;
    for (unsigned index = rangeStart; index < rangeEnd; ++index) {
        GlyphGeometry glyph;
        if (glyph.load(font, geometryScale, msdfgen::GlyphIndex(index), preprocessGeometry)) {
            addGlyph((GlyphGeometry &&) glyph);
            ++loaded;
        }
    }
    if (enableKerning)
        loadKerning(font);
    preferredIdentifierType = GlyphIdentifierType::GLYPH_INDEX;
    return loaded;
}

int FontGeometry::loadGlyphset(msdfgen::FontHandle *font, double fontScale, const Charset &glyphset, bool preprocessGeometry, bool enableKerning) {
    if (!(glyphs->size() == rangeEnd && loadMetrics(font, fontScale)))
        return -1;
    glyphs->reserve(glyphs->size()+glyphset.size());
    int loaded = 0;
    for (unicode_t index : glyphset) {
        GlyphGeometry glyph;
        if (glyph.load(font, geometryScale, msdfgen::GlyphIndex(index), preprocessGeometry)) {
            addGlyph((GlyphGeometry &&) glyph);
            ++loaded;
        }
    }
    if (enableKerning)
        loadKerning(font);
    preferredIdentifierType = GlyphIdentifierType::GLYPH_INDEX;
    return loaded;
}

int FontGeometry::loadCharset(msdfgen::FontHandle *font, double fontScale, const Charset &charset, bool preprocessGeometry, bool enableKerning) {
    if (!(glyphs->size() == rangeEnd && loadMetrics(font, fontScale)))
        return -1;
    glyphs->reserve(glyphs->size()+charset.size());
    int loaded = 0;
    for (unicode_t cp : charset) {
        GlyphGeometry glyph;
        if (glyph.load(font, geometryScale, cp, preprocessGeometry)) {
            addGlyph((GlyphGeometry &&) glyph);
            ++loaded;
        }
    }
    if (enableKerning)
        loadKerning(font);
    preferredIdentifierType = GlyphIdentifierType::UNICODE_CODEPOINT;
    return loaded;
}

bool FontGeometry::loadMetrics(msdfgen::FontHandle *font, double fontScale) {
    if (!msdfgen::getFontMetrics(metrics, font, msdfgen::FONT_SCALING_NONE))
        return false;
    if (metrics.emSize <= 0)
        metrics.emSize = DEFAULT_FONT_UNITS_PER_EM;
    geometryScale = fontScale/metrics.emSize;
    metrics.emSize *= geometryScale;
    metrics.ascenderY *= geometryScale;
    metrics.descenderY *= geometryScale;
    metrics.lineHeight *= geometryScale;
    metrics.underlineY *= geometryScale;
    metrics.underlineThickness *= geometryScale;
    return true;
}

bool FontGeometry::addGlyph(const GlyphGeometry &glyph) {
    if (glyphs->size() != rangeEnd)
        return false;
    glyphsByIndex.insert(std::make_pair(glyph.getIndex(), rangeEnd));
    if (glyph.getCodepoint())
        glyphsByCodepoint.insert(std::make_pair(glyph.getCodepoint(), rangeEnd));
    glyphs->push_back(glyph);
    ++rangeEnd;
    return true;
}

bool FontGeometry::addGlyph(GlyphGeometry &&glyph) {
    if (glyphs->size() != rangeEnd)
        return false;
    glyphsByIndex.insert(std::make_pair(glyph.getIndex(), rangeEnd));
    if (glyph.getCodepoint())
        glyphsByCodepoint.insert(std::make_pair(glyph.getCodepoint(), rangeEnd));
    glyphs->push_back((GlyphGeometry &&) glyph);
    ++rangeEnd;
    return true;
}

int FontGeometry::loadKerning(msdfgen::FontHandle *font) {
    int loaded = 0;
    for (size_t i = rangeStart; i < rangeEnd; ++i)
        for (size_t j = rangeStart; j < rangeEnd; ++j) {
            double advance;
            if (msdfgen::getKerning(advance, font, (*glyphs)[i].getGlyphIndex(), (*glyphs)[j].getGlyphIndex(), msdfgen::FONT_SCALING_NONE) && advance) {
                kerning[std::make_pair<int, int>((*glyphs)[i].getIndex(), (*glyphs)[j].getIndex())] = geometryScale*advance;
                ++loaded;
            }
        }
    return loaded;
}

void FontGeometry::setName(const char *name) {
    if (name)
        this->name = name;
    else
        this->name.clear();
}

double FontGeometry::getGeometryScale() const {
    return geometryScale;
}

const msdfgen::FontMetrics &FontGeometry::getMetrics() const {
    return metrics;
}

GlyphIdentifierType FontGeometry::getPreferredIdentifierType() const {
    return preferredIdentifierType;
}

FontGeometry::GlyphRange FontGeometry::getGlyphs() const {
    return GlyphRange(glyphs, rangeStart, rangeEnd);
}

const GlyphGeometry *FontGeometry::getGlyph(msdfgen::GlyphIndex index) const {
    auto it = glyphsByIndex.find(index.getIndex());
    if (it != glyphsByIndex.end())
        return &(*glyphs)[it->second];
    return nullptr;
}

const GlyphGeometry *FontGeometry::getGlyph(unicode_t codepoint) const {
    auto it = glyphsByCodepoint.find(codepoint);
    if (it != glyphsByCodepoint.end())
        return &(*glyphs)[it->second];
    return nullptr;
}

bool FontGeometry::getAdvance(double &advance, msdfgen::GlyphIndex index1, msdfgen::GlyphIndex index2) const {
    const GlyphGeometry *glyph1 = getGlyph(index1);
    if (!glyph1)
        return false;
    advance = glyph1->getAdvance();
    auto it = kerning.find(std::make_pair<int, int>(index1.getIndex(), index2.getIndex()));
    if (it != kerning.end())
        advance += it->second;
    return true;
}

bool FontGeometry::getAdvance(double &advance, unicode_t codepoint1, unicode_t codepoint2) const {
    const GlyphGeometry *glyph1, *glyph2;
    if (!((glyph1 = getGlyph(codepoint1)) && (glyph2 = getGlyph(codepoint2))))
        return false;
    advance = glyph1->getAdvance();
    auto it = kerning.find(std::make_pair<int, int>(glyph1->getIndex(), glyph2->getIndex()));
    if (it != kerning.end())
        advance += it->second;
    return true;
}

const std::map<std::pair<int, int>, double, std::less<std::pair<int, int>>, Allocator<std::pair<const std::pair<int, int>, double>>>& FontGeometry::getKerning() const {
    return kerning;
}

const char *FontGeometry::getName() const {
    if (name.empty())
        return nullptr;
    return name.c_str();
}

}
