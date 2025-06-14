const std = @import("std");
const builtin = @import("builtin");
const freetype = @import("freetype");

pub fn setAllocator(alloc: ?std.mem.Allocator) void {
    allocator = alloc;
}

pub fn getUsedMemory() usize {
    return used_memory;
}

var allocator: ?std.mem.Allocator = if (builtin.link_libc) std.heap.raw_c_allocator else null;
var used_memory: usize = 0;

export fn msdfAllocate(size: usize) callconv(.c) ?[*]u8 {
    const alloc = allocator orelse return null;
    const x = alloc.alignedAlloc(u8, .of(std.c.max_align_t), size + @sizeOf(std.c.max_align_t)) catch return null;
    std.mem.writeInt(usize, x[0..@sizeOf(usize)], size, .little);
    used_memory += size;
    return x[@sizeOf(std.c.max_align_t)..].ptr;
}

export fn msdfDeallocate(ptr: ?[*]u8, len: usize) callconv(.c) void {
    const alloc = allocator orelse return;
    var valid_ptr = ptr orelse return;
    if (len == 0) return; // Avoid freeing empty slices
    valid_ptr -= @sizeOf(std.c.max_align_t); // Adjust pointer to the start of the allocation
    const size_from_ptr = std.mem.readInt(usize, valid_ptr[0..@sizeOf(usize)], .little);
    alloc.free(valid_ptr[0 .. size_from_ptr + @sizeOf(std.c.max_align_t)]);
    used_memory -= len;
}

pub const Error = error{
    OutOfMemory,
};

pub const Shape = opaque {
    pub fn init() Error!*Shape {
        return msShapeCreate() orelse return error.OutOfMemory;
    }

    pub fn deinit(self: *Shape) void {
        msShapeDestroy(self);
    }

    pub fn addContour(self: *Shape) Error!*Contour {
        return msShapeAddContour(self) orelse return error.OutOfMemory;
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

    pub fn init() Error!*FreetypeHandle {
        return msInitializeFreetype() orelse return error.OutOfMemory;
    }

    pub fn deinit(self: *FreetypeHandle) void {
        msDeinitializeFreetype(self);
    }

    pub fn loadFont(self: *FreetypeHandle, filename: [*:0]const u8) Error!*FontHandle {
        return msLoadFont(self, @ptrCast(filename)) orelse return error.OutOfMemory;
    }

    pub fn loadFontData(self: *FreetypeHandle, data: []const u8) Error!*FontHandle {
        return msLoadFontData(self, @ptrCast(data.ptr), @intCast(data.len)) orelse return error.OutOfMemory;
    }
};

pub const FontHandle = extern struct {
    face: freetype.Face,
    owned: bool = true, // Indicates if the font handle is owned by this structure (true if it should be destroyed with deinit)

    pub fn adoptFreetypeFont(ftFace: freetype.Face) Error!*FontHandle {
        return msAdoptFreetypeFont(ftFace) orelse return error.OutOfMemory;
    }

    pub fn deinit(self: *FontHandle) void {
        std.debug.print("Deinitializing FontHandle: {x}\n", .{@intFromPtr(self)});
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

// msdfatlasgen

pub const Charset = opaque {
    pub fn init() Error!*Charset {
        return msaCharsetCreate() orelse return error.OutOfMemory;
    }
    pub fn ascii() Error!*Charset {
        return msaCharsetASCII() orelse return error.OutOfMemory;
    }
    pub fn deinit(charset: *Charset) void {
        msaCharsetDestroy(charset);
    }
    pub fn add(charset: *Charset, cp: u32) void {
        msaCharsetAdd(charset, cp);
    }
    pub fn remove(charset: *Charset, cp: u32) void {
        msaCharsetRemove(charset, cp);
    }
    pub fn size(charset: *const Charset) usize {
        return msaCharsetSize(charset);
    }

    pub fn addRange(charset: *Charset, range: []const u32) void {
        for (range) |cp| {
            msaCharsetAdd(charset, cp);
        }
    }
};
extern fn msaCharsetCreate() ?*Charset;
extern fn msaCharsetASCII() ?*Charset;
extern fn msaCharsetDestroy(charset: ?*Charset) void;
extern fn msaCharsetAdd(charset: ?*Charset, cp: u32) void;
extern fn msaCharsetRemove(charset: ?*Charset, cp: u32) void;
extern fn msaCharsetSize(charset: ?*const Charset) usize;

pub const GlyphGeometry = opaque {};
pub const GlyphRange = extern struct {
    first: ?*GlyphGeometry = null,
    count: usize = 0,

    pub const EdgeColoringFunction = enum(c_uint) {
        simple = 0,
        ink_trap = 1,
        by_distance = 2,
    };

    pub fn setEdgeColoring(self: *const GlyphRange, index: usize, f: EdgeColoringFunction, angleThreshold: f64, seed: u64) void {
        msaGlyphRangeSetEdgeColoring(self.*, index, f, angleThreshold, seed);
    }

    pub fn getAdvance(self: *const GlyphRange, index: usize) f32 {
        return msaGlyphRangeGetAdvance(self.*, index);
    }

    pub const Rect = struct {
        x: u32 = 0,
        y: u32 = 0,
        w: u32 = 0,
        h: u32 = 0,
    };

    pub fn getBoxRect(self: *const GlyphRange, index: usize) Rect {
        var x: c_int = 0;
        var y: c_int = 0;
        var w: c_int = 0;
        var h: c_int = 0;
        msaGlyphRangeGetBoxRect(self.*, index, &x, &y, &w, &h);
        return Rect{ .x = @intCast(x), .y = @intCast(y), .w = @intCast(w), .h = @intCast(h) };
    }

    pub const QuadPlaneBounds = struct {
        left: f64 = 0,
        bottom: f64 = 0,
        right: f64 = 0,
        top: f64 = 0,
    };

    pub fn getQuadPlaneBounds(self: *const GlyphRange, index: usize) QuadPlaneBounds {
        var l: f64 = 0;
        var b: f64 = 0;
        var r: f64 = 0;
        var t: f64 = 0;
        msaGlyphRangeGetQuadPlaneBounds(self.*, index, &l, &b, &r, &t);
        return QuadPlaneBounds{ .left = l, .bottom = b, .right = r, .top = t };
    }

    pub fn getGlyphIndex(self: *const GlyphRange, index: usize) GlyphIndex {
        return @enumFromInt(msaGlyphRangeGetGlyphIndex(self.*, index));
    }

    pub fn getCodepoint(self: *const GlyphRange, index: usize) u32 {
        return msaGlyphRangeGetCodepoint(self.*, index);
    }
};

extern fn msaGlyphRangeSetEdgeColoring(range: GlyphRange, index: usize, f: GlyphRange.EdgeColoringFunction, angleThreshold: f64, seed: c_ulonglong) void;
extern fn msaGlyphRangeGetAdvance(range: GlyphRange, index: usize) f32;
extern fn msaGlyphRangeGetBoxRect(range: GlyphRange, index: usize, x: [*c]c_int, y: [*c]c_int, w: [*c]c_int, h: [*c]c_int) void;
extern fn msaGlyphRangeGetQuadPlaneBounds(range: GlyphRange, index: usize, l: [*c]f64, b: [*c]f64, r: [*c]f64, t: [*c]f64) void;
extern fn msaGlyphRangeGetGlyphIndex(range: GlyphRange, index: usize) usize;
extern fn msaGlyphRangeGetCodepoint(range: GlyphRange, index: usize) u32;

pub const FontGeometry = opaque {
    pub fn init() Error!*FontGeometry {
        return msaFontGeometryCreate() orelse return error.OutOfMemory;
    }
    pub fn deinit(fontGeometry: *FontGeometry) void {
        msaFontGeometryDestroy(fontGeometry);
    }
    /// returns number of glyphs loaded
    pub fn loadCharset(fontGeometry: *FontGeometry, font: *const FontHandle, fontScale: f64, charset: *const Charset) c_int {
        return msaFontGeometryLoadCharset(fontGeometry, font, fontScale, charset);
    }
    pub fn getGlyphs(fontGeometry: *const FontGeometry) GlyphRange {
        return msaFontGeometryGetGlyphs(fontGeometry);
    }
};
extern fn msaFontGeometryCreate() ?*FontGeometry;
extern fn msaFontGeometryDestroy(fontGeometry: ?*FontGeometry) void;
extern fn msaFontGeometryLoadCharset(fontGeometry: ?*FontGeometry, font: *const FontHandle, fontScale: f64, charset: ?*const Charset) c_int;
extern fn msaFontGeometryGetGlyphs(fontGeometry: ?*const FontGeometry) GlyphRange;

pub const Packer = opaque {
    pub const DimensionConstraint = enum(c_uint) {
        none = 0,
        square = 1,
        even_square = 2,
        multiple_of_four_square = 3,
        power_of_two_rectangle = 4,
        power_of_two_square = 5,
    };

    pub fn init() Error!*Packer {
        return msaPackerCreate() orelse return error.OutOfMemory;
    }
    pub fn deinit(packer: *Packer) void {
        msaPackerDestroy(packer);
    }

    pub fn pack(packer: *Packer, range: GlyphRange) c_int {
        return msaPackerPack(packer, range);
    }
    pub fn setDimensions(packer: *Packer, width: c_int, height: c_int) void {
        msaPackerSetDimensions(packer, width, height);
    }
    pub fn unsetDimensions(packer: *Packer) void {
        msaPackerUnsetDimensions(packer);
    }
    pub fn setDimensionsConstraint(packer: *Packer, dimensionsConstraint: DimensionConstraint) void {
        msaPackerSetDimensionsConstraint(packer, dimensionsConstraint);
    }
    pub fn setSpacing(packer: *Packer, spacing: c_int) void {
        msaPackerSetSpacing(packer, spacing);
    }
    pub fn setScale(packer: *Packer, scale: f64) void {
        msaPackerSetScale(packer, scale);
    }
    pub fn setMinimumScale(packer: *Packer, minScale: f64) void {
        msaPackerSetMinimumScale(packer, minScale);
    }
    pub fn setUnitRange(packer: *Packer, unitLower: f64, unitUpper: f64) void {
        msaPackerSetUnitRange(packer, unitLower, unitUpper);
    }
    pub fn setPixelRange(packer: *Packer, pxLower: f64, pxUpper: f64) void {
        msaPackerSetPixelRange(packer, pxLower, pxUpper);
    }
    pub fn setMiterLimit(packer: *Packer, miterLimit: f64) void {
        msaPackerSetMiterLimit(packer, miterLimit);
    }
    pub fn setOriginPixelAlignment(packer: *Packer, @"align": bool) void {
        msaPackerSetOriginPixelAlignment(packer, @"align");
    }
    pub fn setOriginPixelAlignmentXY(packer: *Packer, alignX: bool, alignY: bool) void {
        msaPackerSetOriginPixelAlignmentXY(packer, alignX, alignY);
    }
    pub fn setInnerUnitPadding(packer: *Packer, l: f64, b: f64, r: f64, t: f64) void {
        msaPackerSetInnerUnitPadding(packer, l, b, r, t);
    }
    pub fn setOuterUnitPadding(packer: *Packer, l: f64, b: f64, r: f64, t: f64) void {
        msaPackerSetOuterUnitPadding(packer, l, b, r, t);
    }
    pub fn setInnerPixelPadding(packer: *Packer, l: f64, b: f64, r: f64, t: f64) void {
        msaPackerSetInnerPixelPadding(packer, l, b, r, t);
    }
    pub fn setOuterPixelPadding(packer: *Packer, l: f64, b: f64, r: f64, t: f64) void {
        msaPackerSetOuterPixelPadding(packer, l, b, r, t);
    }
    pub fn getDimensions(packer: *const Packer) struct {
        width: c_int = 0,
        height: c_int = 0,
    } {
        var width: c_int = 0;
        var height: c_int = 0;
        msaPackerGetDimensions(packer, &width, &height);
        return .{
            .width = width,
            .height = height,
        };
    }
    pub fn getScale(packer: *const Packer) f64 {
        return msaPackerGetScale(packer);
    }
    pub fn getPixelRange(packer: *const Packer) struct {
        pxLower: f64 = 0,
        pxUpper: f64 = 0,
    } {
        var pxLower: f64 = 0;
        var pxUpper: f64 = 0;
        msaPackerGetPixelRange(packer, &pxLower, &pxUpper);
        return .{
            .pxLower = pxLower,
            .pxUpper = pxUpper,
        };
    }
};

extern fn msaPackerCreate() ?*Packer;
extern fn msaPackerDestroy(packer: ?*Packer) void;
extern fn msaPackerPack(packer: ?*Packer, range: GlyphRange) c_int;
extern fn msaPackerSetDimensions(packer: ?*Packer, width: c_int, height: c_int) void;
extern fn msaPackerUnsetDimensions(packer: ?*Packer) void;
extern fn msaPackerSetDimensionsConstraint(packer: ?*Packer, dimensionsConstraint: Packer.DimensionConstraint) void;
extern fn msaPackerSetSpacing(packer: ?*Packer, spacing: c_int) void;
extern fn msaPackerSetScale(packer: ?*Packer, scale: f64) void;
extern fn msaPackerSetMinimumScale(packer: ?*Packer, minScale: f64) void;
extern fn msaPackerSetUnitRange(packer: ?*Packer, unitLower: f64, unitUpper: f64) void;
extern fn msaPackerSetPixelRange(packer: ?*Packer, pxLower: f64, pxUpper: f64) void;
extern fn msaPackerSetMiterLimit(packer: ?*Packer, miterLimit: f64) void;
extern fn msaPackerSetOriginPixelAlignment(packer: ?*Packer, @"align": bool) void;
extern fn msaPackerSetOriginPixelAlignmentXY(packer: ?*Packer, alignX: bool, alignY: bool) void;
extern fn msaPackerSetInnerUnitPadding(packer: ?*Packer, l: f64, b: f64, r: f64, t: f64) void;
extern fn msaPackerSetOuterUnitPadding(packer: ?*Packer, l: f64, b: f64, r: f64, t: f64) void;
extern fn msaPackerSetInnerPixelPadding(packer: ?*Packer, l: f64, b: f64, r: f64, t: f64) void;
extern fn msaPackerSetOuterPixelPadding(packer: ?*Packer, l: f64, b: f64, r: f64, t: f64) void;
extern fn msaPackerGetDimensions(packer: ?*const Packer, width: [*c]c_int, height: [*c]c_int) void;
extern fn msaPackerGetScale(packer: ?*const Packer) f64;
extern fn msaPackerGetPixelRange(packer: ?*const Packer, pxLower: [*c]f64, pxUpper: [*c]f64) void;

pub fn BitmapConstRef(comptime T: type, comptime Channels: u8) type {
    return struct {
        const Self = @This();

        data: ?[*]align(1) const T = null,
        width: u32 = 0,
        height: u32 = 0,

        pub fn slice(self: *const Self) []align(1) const T {
            if (self.data) |data| {
                return data[0 .. self.width * self.height * @as(usize, Channels)];
            } else {
                return &.{};
            }
        }

        pub fn byteSlice(self: *const Self) []const u8 {
            return std.mem.bytesAsSlice(u8, self.slice());
        }
    };
}

pub const ImmediateAtlasGenerator = opaque {
    pub fn init(width: u32, height: u32) Error!*ImmediateAtlasGenerator {
        return msaImmediateAtlasGeneratorCreate(width, height) orelse return error.OutOfMemory;
    }
    pub fn deinit(generator: *ImmediateAtlasGenerator) void {
        msaImmediateAtlasGeneratorDestroy(generator);
    }
    pub fn setThreadCount(generator: *ImmediateAtlasGenerator, threadCount: c_int) void {
        msaImmediateAtlasGeneratorSetThreadCount(generator, threadCount);
    }
    pub fn generate(generator: *ImmediateAtlasGenerator, range: GlyphRange) void {
        msaImmediateAtlasGeneratorGenerate(generator, range);
    }
    pub fn getBitmap(generator: *ImmediateAtlasGenerator) BitmapConstRef(f32, 3) {
        var width_out: c_int = 0;
        var height_out: c_int = 0;
        const data = msaImmediateAtlasGeneratorGetBitmap(generator, &width_out, &height_out);
        return .{
            .data = @ptrCast(data),
            .width = @intCast(width_out),
            .height = @intCast(height_out),
        };
    }
};

extern fn msaImmediateAtlasGeneratorCreate(width: u32, height: u32) ?*ImmediateAtlasGenerator;
extern fn msaImmediateAtlasGeneratorDestroy(generator: ?*ImmediateAtlasGenerator) void;
extern fn msaImmediateAtlasGeneratorSetThreadCount(generator: ?*ImmediateAtlasGenerator, threadCount: c_int) void;
extern fn msaImmediateAtlasGeneratorGenerate(generator: ?*ImmediateAtlasGenerator, range: GlyphRange) void;
extern fn msaImmediateAtlasGeneratorGetBitmap(generator: ?*ImmediateAtlasGenerator, width: [*c]c_int, height: [*c]c_int) [*c]f32;
