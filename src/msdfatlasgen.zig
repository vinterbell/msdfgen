const msdfgen = @import("msdfgen");
const std = @import("std");

pub const Charset = opaque {
    pub fn init() ?*Charset {
        return msaCharsetCreate();
    }
    pub fn ascii() ?*Charset {
        return msaCharsetASCII();
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

    pub fn getGlyphIndex(self: *const GlyphRange, index: usize) msdfgen.GlyphIndex {
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
    pub fn init() ?*FontGeometry {
        return msaFontGeometryCreate();
    }
    pub fn deinit(fontGeometry: *FontGeometry) void {
        msaFontGeometryDestroy(fontGeometry);
    }
    /// returns number of glyphs loaded
    pub fn loadCharset(fontGeometry: *FontGeometry, font: *const msdfgen.FontHandle, fontScale: f64, charset: *const Charset) c_int {
        return msaFontGeometryLoadCharset(fontGeometry, font, fontScale, charset);
    }
    pub fn getGlyphs(fontGeometry: *const FontGeometry) GlyphRange {
        return msaFontGeometryGetGlyphs(fontGeometry);
    }
};
extern fn msaFontGeometryCreate() ?*FontGeometry;
extern fn msaFontGeometryDestroy(fontGeometry: ?*FontGeometry) void;
extern fn msaFontGeometryLoadCharset(fontGeometry: ?*FontGeometry, font: *const msdfgen.FontHandle, fontScale: f64, charset: ?*const Charset) c_int;
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

    pub fn init() ?*Packer {
        return msaPackerCreate();
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
    pub fn init(width: u32, height: u32) ?*ImmediateAtlasGenerator {
        return msaImmediateAtlasGeneratorCreate(width, height);
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
