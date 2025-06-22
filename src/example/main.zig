const std = @import("std");
const msdfgen = @import("msdfgen");
const msdfgenold = @import("msdfgenold");

pub fn main() !void {
    var dbg_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = dbg_allocator.deinit();
    const allocator = dbg_allocator.allocator();

    const char = 'r';

    const arial_windows_path = "C:\\Windows\\Fonts\\arial.ttf";
    const arial_bytes = try std.fs.cwd().readFileAlloc(
        allocator,
        arial_windows_path,
        std.math.maxInt(usize),
    );
    defer allocator.free(arial_bytes);

    {
        const ttf: msdfgen.TrueType = try .load(arial_bytes);

        var shape = msdfgen.Shape.init(allocator);
        defer shape.deinit();

        const glyph_a = ttf.codepointGlyphIndex(char) orelse {
            std.log.err("Glyph not found in font: {s}", .{"0"});
            return error.GlyphNotFound;
        };
        try msdfgen.font.loadGlyph(
            &ttf,
            allocator,
            &shape,
            glyph_a,
            .em_normalized,
        );
        try shape.normalize();
        try msdfgen.edgeColoringSimple(&shape, 3.0, 0, allocator);

        var my_bitmap: msdfgen.Bitmap(f32, 3) = try .init(allocator, 32, 32);
        defer my_bitmap.deinit();

        var config: msdfgen.MSDFGeneratorConfig = .default;
        config.generator.allocator = allocator;

        try msdfgen.generateMSDF(my_bitmap.ref(), &shape, .init(
            .init(.init(32.0, 32.0), .init(0.125, 0.125)),
            .fromRange(.symmetrical(0.125)),
        ), config);

        const out_writer = std.io.getStdOut().writer();

        // print it as ascii art
        for (0..my_bitmap.data.height) |y| {
            const row = if (shape.inverse_y_axis) my_bitmap.data.height - y - 1 else y;
            for (0..my_bitmap.data.width) |x| {
                const pixel: [3]f32 = my_bitmap.constRef().getPixel(@intCast(x), @intCast(row));
                const median = msdfgen.util.median(f32, pixel[0], pixel[1], pixel[2]);
                const index = @max(median / 0.25, 0);

                const c: u8 = ascii_fill[@as(usize, @intFromFloat(index))];
                out_writer.print("{c} ", .{c}) catch {};
            }
            out_writer.print("\n", .{}) catch {};
        }

        std.debug.print(
            "Bitmap size: {d}x{d}\n",
            .{
                my_bitmap.data.width,
                my_bitmap.data.height,
            },
        );

        // print all edges in contours
        std.debug.print("Shape has {d} contours :\n", .{shape.contours.items.len});
        for (shape.contours.items) |contour| {
            std.debug.print("Contour with {d} edges:\n", .{contour.edges.items.len});
            for (contour.edges.items) |edge| {
                const p0 = edge.point(0.0);
                const p1 = edge.point(1.0);
                std.debug.print("  Edge {} from ({d:.6}, {d:.6}) to ({d:.6}, {d:.6})\n", .{
                    @intFromEnum(edge.kind) + 1, p0.x, p0.y, p1.x, p1.y,
                });
            }
        }
    }

    // use old
    {
        var shape: *msdfgenold.Shape = try .init();
        defer shape.deinit();

        var ft: *msdfgenold.FreetypeHandle = try .init();
        // defer ft.deinit();

        var font = try ft.loadFontData(arial_bytes);
        // defer font.deinit();

        const advance = font.loadGlyph(shape, char, .EM_NORMALIZED);
        _ = advance;

        shape.normalize();
        shape.edgeColoringSimple(3.0, 0.0);

        const data = allocator.alloc(f32, 32 * 32 * 3) catch return error.OutOfMemory;
        defer allocator.free(data);

        shape.generateMSDF(.{
            .data = data.ptr,
            .w = 32,
            .h = 32,
            .sx = 32.0,
            .sy = 32.0,
            .dx = 0.125,
            .dy = 0.125,
            .range = 0.125,
        });

        const out_writer = std.io.getStdOut().writer();
        // print it as ascii art
        for (0..32) |y| {
            const row = 32 - y - 1;
            for (0..32) |x| {
                const index = @max(
                    @as(f32, data[(row * 32 + x) * 3 + 0]) / 0.25,
                    0,
                );
                const c: u8 = ascii_fill[@as(usize, @intFromFloat(index))];
                out_writer.print("{c} ", .{c}) catch {};
            }
            out_writer.print("\n", .{}) catch {};
        }
    }
}

const ascii_fill = " .:-=+*%@#####################################";
