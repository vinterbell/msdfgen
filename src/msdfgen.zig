const std = @import("std");
const builtin = @import("builtin");
const freetype = @import("freetype");

pub const Shape = opaque {
    pub fn init() ?*Shape {
        return msShapeCreate();
    }

    pub fn deinit(self: *Shape) void {
        msShapeDestroy(self);
    }

    pub fn addContour(self: *Shape) ?*Contour {
        return msShapeAddContour(self);
    }

    pub fn normalize(self: *Shape) void {
        msShapeNormalize(self);
    }

    pub fn orientContours(self: *Shape) void {
        msShapeOrientContours(self);
    }

    pub fn edgeColoringSimple(self: *Shape, angle_threshold: f64, seed: u64) void {
        msEdgeColoringSimple(self, angle_threshold, @intCast(seed));
    }

    pub const GenerateDesc = struct {
        data: [*]f32,
        w: c_int,
        h: c_int,
        range: f64,
        sx: f64,
        sy: f64,
        dx: f64,
        dy: f64,
    };

    // generator functions
    /// 1 byte per pixel
    pub fn generateSDF(self: *Shape, desc: GenerateDesc) void {
        msGenerateSDF(desc.data, desc.w, desc.h, self, desc.range, desc.sx, desc.sy, desc.dx, desc.dy);
    }
    /// 1 byte per pixel
    pub fn generatePseudoSDF(self: *Shape, desc: GenerateDesc) void {
        msGeneratePseudoSDF(desc.data, desc.w, desc.h, self, desc.range, desc.sx, desc.sy, desc.dx, desc.dy);
    }
    /// 3 bytes per pixel
    pub fn generateMSDF(self: *Shape, desc: GenerateDesc) void {
        msGenerateMSDF(desc.data, desc.w, desc.h, self, desc.range, desc.sx, desc.sy, desc.dx, desc.dy);
    }
    /// 4 bytes per pixel
    pub fn generateMTSDF(self: *Shape, desc: GenerateDesc) void {
        msGenerateMTSDF(desc.data, desc.w, desc.h, self, desc.range, desc.sx, desc.sy, desc.dx, desc.dy);
    }
};

pub const Contour = opaque {
    pub fn addLinearEdge(self: *Contour, x1: f64, y1: f64, x2: f64, y2: f64) void {
        msContourAddLinearEdge(self, x1, y1, x2, y2);
    }

    pub fn addQuadraticEdge(self: *Contour, x1: f64, y1: f64, x2: f64, y2: f64, x3: f64, y3: f64) void {
        msContourAddQuadraticEdge(self, x1, y1, x2, y2, x3, y3);
    }

    pub fn addCubicEdge(self: *Contour, x1: f64, y1: f64, x2: f64, y2: f64, x3: f64, y3: f64, x4: f64, y4: f64) void {
        msContourAddCubicEdge(self, x1, y1, x2, y2, x3, y3, x4, y4);
    }
};

extern fn msShapeCreate() ?*Shape;
extern fn msShapeDestroy(shape: ?*Shape) void;
extern fn msShapeAddContour(shape: ?*Shape) ?*Contour;
extern fn msShapeNormalize(cShape: ?*Shape) void;
extern fn msShapeOrientContours(cShape: ?*Shape) void;
extern fn msEdgeColoringSimple(cShape: ?*Shape, angleThreshold: f64, seed: c_ulonglong) void;
extern fn msContourAddLinearEdge(cContour: ?*Contour, x1: f64, y1: f64, x2: f64, y2: f64) void;
extern fn msContourAddQuadraticEdge(cContour: ?*Contour, x1: f64, y1: f64, x2: f64, y2: f64, x3: f64, y3: f64) void;
extern fn msContourAddCubicEdge(cContour: ?*Contour, x1: f64, y1: f64, x2: f64, y2: f64, x3: f64, y3: f64, x4: f64, y4: f64) void;
extern fn msGenerateSDF(data: [*c]f32, w: c_int, h: c_int, shape: ?*Shape, range: f64, sx: f64, sy: f64, dx: f64, dy: f64) void;
extern fn msGeneratePseudoSDF(data: [*c]f32, w: c_int, h: c_int, shape: ?*Shape, range: f64, sx: f64, sy: f64, dx: f64, dy: f64) void;
extern fn msGenerateMSDF(data: [*c]f32, w: c_int, h: c_int, shape: ?*Shape, range: f64, sx: f64, sy: f64, dx: f64, dy: f64) void;
extern fn msGenerateMTSDF(data: [*c]f32, w: c_int, h: c_int, shape: ?*Shape, range: f64, sx: f64, sy: f64, dx: f64, dy: f64) void;

pub const FreetypeHandle = extern struct {
    library: freetype.Library,

    pub fn init() ?*FreetypeHandle {
        return msInitializeFreetype();
    }

    pub fn deinit(self: *FreetypeHandle) void {
        msDeinitializeFreetype(self);
    }

    pub fn loadFont(self: *FreetypeHandle, filename: [*:0]const u8) ?*FontHandle {
        return msLoadFont(self, @ptrCast(filename));
    }

    pub fn loadFontData(self: *FreetypeHandle, data: []const u8) ?*FontHandle {
        return msLoadFontData(self, @ptrCast(data.ptr), @intCast(data.len));
    }
};

pub const FontHandle = extern struct {
    face: freetype.Face,
    owned: bool = true, // Indicates if the font handle is owned by this structure (true if it should be destroyed with deinit)

    pub fn adoptFreetypeFont(ftFace: freetype.Face) ?*FontHandle {
        return msAdoptFreetypeFont(ftFace);
    }

    pub fn deinit(self: *FontHandle) void {
        msDestroyFont(self);
    }

    pub fn getMetrics(self: *FontHandle, coordinate_scaling: FontCoordinateScaling) ?FontMetrics {
        var metrics: FontMetrics = undefined;
        if (msGetFontMetrics(&metrics, self, coordinate_scaling)) {
            return metrics;
        } else {
            return null;
        }
    }

    pub fn getWhitespaceWidth(self: *FontHandle, coordinate_scaling: FontCoordinateScaling) ?struct {
        space_advance: f64 = 0.0,
        tab_advance: f64 = 0.0,
    } {
        var space_advance: f64 = 0.0;
        var tab_advance: f64 = 0.0;
        if (msGetFontWhitespaceWidth(
            &space_advance,
            &tab_advance,
            self,
            coordinate_scaling,
        )) {
            return .{ .space_advance = space_advance, .tab_advance = tab_advance };
        } else {
            return null;
        }
    }

    pub fn getGlyphCount(self: *FontHandle) ?u32 {
        var count: c_uint = 0;
        if (msGetGlyphCount(&count, self)) {
            return @intCast(count);
        } else {
            return null;
        }
    }

    pub fn getGlyphIndex(self: *FontHandle, unicode: u21) ?GlyphIndex {
        var glyph_index: GlyphIndex = undefined;
        if (msGetGlyphIndex(&glyph_index, self, unicode)) {
            return glyph_index;
        } else {
            return null;
        }
    }

    pub fn loadGlyph(
        self: *FontHandle,
        output: *Shape,
        unicode: u21,
        coordinate_scaling: FontCoordinateScaling,
    ) ?f64 {
        var advance: f64 = 0.0;
        if (msLoadGlyph(output, self, unicode, coordinate_scaling, &advance)) {
            return advance;
        } else {
            return null;
        }
    }

    pub fn getKerning(
        self: *FontHandle,
        glyph_index0: GlyphIndex,
        glyph_index1: GlyphIndex,
        coordinate_scaling: FontCoordinateScaling,
    ) ?f64 {
        var kerning: f64 = 0.0;
        if (msGetKerning(&kerning, self, glyph_index0, glyph_index1, coordinate_scaling)) {
            return kerning;
        } else {
            return null;
        }
    }
};

pub fn readFreetypeOutline(output: *Shape, outline: *freetype.Outline, scale: f64) freetype.Error {
    return msReadFreetypeOutline(output, outline, scale);
}

pub const GlyphIndex = enum(c_uint) {
    _,
};

pub const FontMetrics = extern struct {
    em_size: f64 = 0.0,
    ascender_y: f64 = 0.0,
    descender_y: f64 = 0.0,
    line_height: f64 = 0.0,
    underline_y: f64 = 0.0,
    underline_thickness: f64 = 0.0,
};

pub const FontVariationAxis = extern struct {
    name: ?[*:0]const u8 = null,
    min: f64 = 0.0,
    max: f64 = 0.0,
    default: f64 = 0.0,
};

pub const FontCoordinateScaling = enum(c_uint) {
    NONE = 0,
    EM_NORMALIZED = 1,
    LEGACY = 2,
};

const unicode_t = u32;
extern fn msInitializeFreetype() ?*FreetypeHandle;
extern fn msDeinitializeFreetype(library: ?*FreetypeHandle) void;
extern fn msAdoptFreetypeFont(ftFace: freetype.Face) ?*FontHandle;
extern fn msReadFreetypeOutline(output: ?*Shape, outline: ?*freetype.Outline, scale: f64) freetype.Error;
extern fn msLoadFont(library: ?*FreetypeHandle, filename: [*c]const u8) ?*FontHandle;
extern fn msLoadFontData(library: ?*FreetypeHandle, data: [*c]const u8, length: c_int) ?*FontHandle;
extern fn msDestroyFont(font: ?*FontHandle) void;
extern fn msGetFontMetrics(metrics: [*c]FontMetrics, font: ?*FontHandle, coordinateScaling: FontCoordinateScaling) bool;
extern fn msGetFontWhitespaceWidth(spaceAdvance: [*c]f64, tabAdvance: [*c]f64, font: ?*FontHandle, coordinateScaling: FontCoordinateScaling) bool;
extern fn msGetGlyphCount(output: [*c]c_uint, font: ?*FontHandle) bool;
extern fn msGetGlyphIndex(glyphIndex: [*c]GlyphIndex, font: ?*FontHandle, unicode: unicode_t) bool;
extern fn msLoadGlyph(output: ?*Shape, font: ?*FontHandle, unicode: unicode_t, coordinateScaling: FontCoordinateScaling, outAdvance: [*c]f64) bool;
extern fn msGetKerning(output: [*c]f64, font: ?*FontHandle, glyphIndex0: GlyphIndex, glyphIndex1: GlyphIndex, coordinateScaling: FontCoordinateScaling) bool;
