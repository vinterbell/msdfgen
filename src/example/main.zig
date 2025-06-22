const std = @import("std");
const msdfgen = @import("msdfgen");
const msdfgenold = @import("msdfgenold");

const stb = @import("stb");

pub fn main() !void {
    var dbg_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer _ = dbg_allocator.deinit();
    const allocator = dbg_allocator.allocator();

    const char = 'A';

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

        var my_bitmap: msdfgen.Bitmap(f32, 3) = try .init(allocator, 64, 64);
        defer my_bitmap.deinit();

        var config: msdfgen.MSDFGeneratorConfig = .default;
        config.generator.allocator = allocator;

        try msdfgen.generateMSDF(my_bitmap.ref(), &shape, .init(
            .init(.init(64.0, 64.0), .init(0.125, 0.125)),
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

        stb.init(allocator);
        defer stb.deinit();

        var img = try stb.Image.createEmpty(64, 64, 4, .{
            .bytes_per_component = 4,
            .bytes_per_row = 64 * 4 * 4,
        });
        defer img.deinit();

        const float_data_src = my_bitmap.data.slice();
        const float_data_dst = std.mem.bytesAsSlice(f32, img.data);
        for (0..my_bitmap.data.height) |y| {
            const row_dst = my_bitmap.data.height - y - 1;
            const row_src = y;
            for (0..my_bitmap.data.width) |x| {
                const src_index = (row_dst * my_bitmap.data.width + x) * 3;
                const dst_index = (row_src * my_bitmap.data.width + x) * 4;

                float_data_dst[dst_index + 0] = float_data_src[src_index + 0];
                float_data_dst[dst_index + 1] = float_data_src[src_index + 1];
                float_data_dst[dst_index + 2] = float_data_src[src_index + 2];
                float_data_dst[dst_index + 3] = 1.0;

                // the sdf as if it was on the gpu
                // const value = msdfgen.util.median(
                //     f32,
                //     float_data_src[src_index + 0],
                //     float_data_src[src_index + 1],
                //     float_data_src[src_index + 2],
                // );
                // float_data_dst[dst_index + 0] = value;
                // float_data_dst[dst_index + 1] = value;
                // float_data_dst[dst_index + 2] = value;
                // float_data_dst[dst_index + 3] = 1.0; // alpha
            }
        }

        try img.writeToFile("glyph.hdr", .hdr);
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

        const data = allocator.alloc(f32, 64 * 64 * 3) catch return error.OutOfMemory;
        defer allocator.free(data);

        shape.generateMSDF(.{
            .data = data.ptr,
            .w = 64,
            .h = 64,
            .sx = 64.0,
            .sy = 64.0,
            .dx = 0.125,
            .dy = 0.125,
            .range = 0.125,
        });

        const out_writer = std.io.getStdOut().writer();
        // print it as ascii art
        for (0..64) |y| {
            const row = 64 - y - 1;
            for (0..64) |x| {
                const index = @max(
                    @as(f64, data[(row * 64 + x) * 3 + 0]) / 0.25,
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
