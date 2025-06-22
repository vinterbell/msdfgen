const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zon = @import("build.zig.zon");
    const version = std.SemanticVersion.parse(zon.version) catch |err| {
        std.log.err("Failed to parse version: {}", .{err});
        return err;
    };

    const freetype_dep = b.dependency("freetype", .{
        .target = target,
        .optimize = .ReleaseFast,
    });

    // need to link this if not using zig or own allocator
    const zigless_allocation_shim = b.addLibrary(.{
        .name = "msdfgen-malloc-shim",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .version = version,
    });
    zigless_allocation_shim.addCSourceFile(.{
        .file = b.path("src/memory.cpp"),
        .flags = &.{
            "-std=c++17",
            "-fno-sanitize=undefined",
        },
    });
    if (target.result.abi != .msvc) {
        zigless_allocation_shim.root_module.link_libcpp = true;
    }
    b.installArtifact(zigless_allocation_shim);

    const libgen = b.addLibrary(.{
        .name = "msdfgen",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .version = version,
    });
    if (target.result.abi != .msvc) {
        libgen.root_module.link_libcpp = true;
    }
    libgen.root_module.addCMacro("MSDFGEN_USE_CPP11", "1");
    libgen.root_module.addCMacro("MSDFGEN_VERSION", b.fmt("{}", .{version}));
    libgen.root_module.addCMacro("MSDFGEN_VERSION_MAJOR", b.fmt("{}", .{version.major}));
    libgen.root_module.addCMacro("MSDFGEN_VERSION_MINOR", b.fmt("{}", .{version.minor}));
    libgen.root_module.addCMacro("MSDFGEN_VERSION_REVISION", b.fmt("{}", .{version.patch}));

    libgen.linkLibrary(freetype_dep.artifact("freetype"));
    libgen.addCSourceFiles(.{
        .root = b.path("core"),
        .files = &.{
            "contour-combiners.cpp",
            "Contour.cpp",
            "DistanceMapping.cpp",
            "edge-coloring.cpp",
            "edge-segments.cpp",
            "edge-selectors.cpp",
            "EdgeHolder.cpp",
            "equation-solver.cpp",
            "export-svg.cpp",
            "msdf-error-correction.cpp",
            "MSDFErrorCorrection.cpp",
            "msdfgen.cpp",
            "msdfgen-c.cpp",
            "Projection.cpp",
            "rasterization.cpp",
            "render-sdf.cpp",
            "save-bmp.cpp",
            "save-fl32.cpp",
            "save-rgba.cpp",
            "save-tiff.cpp",
            "Scanline.cpp",
            "sdf-error-estimation.cpp",
            "shape-description.cpp",
            "Shape.cpp",
        },
        .language = .cpp,
        .flags = &.{
            "-std=c++17",
            "-fno-sanitize=undefined",
        },
    });
    libgen.addCSourceFiles(.{
        .root = b.path("ext"),
        .files = &.{
            "import-font.cpp",
            "import-font-c.cpp",
            "import-svg.cpp",
            "resolve-shape-geometry.cpp",
            "save-png.cpp",
        },
        .language = .cpp,
        .flags = &.{
            "-std=c++17",
            "-fno-sanitize=undefined",
        },
    });
    libgen.installHeader(b.path("msdfgen.h"), "msdfgen.h");
    libgen.installHeader(b.path("msdfgen-c.h"), "msdfgen-c.h");
    libgen.installHeader(b.path("msdfgen-ext.h"), "msdfgen-ext.h");
    libgen.installHeadersDirectory(b.path("core"), "core", .{
        .include_extensions = &.{ ".hpp", ".h" },
    });
    libgen.installHeadersDirectory(b.path("ext"), "ext", .{
        .include_extensions = &.{ ".hpp", ".h" },
    });
    b.installArtifact(libgen);

    const libatlasgen = b.addLibrary(.{
        .name = "msdfatlasgen",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .version = version,
    });
    if (target.result.abi != .msvc) {
        libatlasgen.root_module.link_libcpp = true;
    }
    const epoch_seconds: std.time.epoch.EpochSeconds = .{
        .secs = @intCast(std.time.timestamp()),
    };
    const epoch_day = epoch_seconds.getEpochDay();
    libatlasgen.root_module.addCMacro("MSDF_ATLAS_NO_ARTERY_FONT", "1");
    libatlasgen.root_module.addCMacro("MSDF_ATLAS_VERSION", b.fmt("{}", .{version}));
    libatlasgen.root_module.addCMacro("MSDF_ATLAS_VERSION_MAJOR", b.fmt("{}", .{version.major}));
    libatlasgen.root_module.addCMacro("MSDF_ATLAS_VERSION_MINOR", b.fmt("{}", .{version.minor}));
    libatlasgen.root_module.addCMacro("MSDF_ATLAS_VERSION_REVISION", b.fmt("{}", .{version.patch}));
    libatlasgen.root_module.addCMacro("MSDF_ATLAS_COPYRIGHT_YEAR", b.fmt("{}", .{epoch_day.calculateYearDay().year}));
    libatlasgen.linkLibrary(libgen);
    libatlasgen.addCSourceFiles(.{
        .root = b.path("msdf-atlas-gen"),
        .files = &.{
            "artery-font-export.cpp",
            "bitmap-blit.cpp",
            "charset-parser.cpp",
            "Charset.cpp",
            "csv-export.cpp",
            "FontGeometry.cpp",
            "glyph-generators.cpp",
            "GlyphGeometry.cpp",
            "GridAtlasPacker.cpp",
            "image-encode.cpp",
            "json-export.cpp",
            "main.cpp",
            "msdf-atlas-gen-c.cpp",
            "Padding.cpp",
            "RectanglePacker.cpp",
            "shadron-preview-generator.cpp",
            "size-selectors.cpp",
            "TightAtlasPacker.cpp",
            "utf8.cpp",
            "Workload.cpp",
        },
        .language = .cpp,
        .flags = &.{
            "-std=c++17",
            "-fno-sanitize=undefined",
        },
    });
    libatlasgen.installHeadersDirectory(b.path("msdf-atlas-gen/"), "msdf-atlas-gen/", .{
        .include_extensions = &.{ ".hpp", ".h" },
    });
    b.installArtifact(libgen);
    b.installArtifact(libatlasgen);

    // includes both atlasgen and msdfgen
    const msdfgen = b.addModule("msdfgen", .{
        .root_source_file = b.path("src/msdfgen.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "freetype", .module = freetype_dep.module("zfreetype") },
        },
    });
    msdfgen.linkLibrary(libgen);
    msdfgen.linkLibrary(libatlasgen);

    // new rewrite
    const zmsdfgen = b.addModule("zmsdfgen", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "freetype", .module = freetype_dep.module("zfreetype") },
        },
    });

    const example_mod = b.createModule(.{
        .root_source_file = b.path("src/example/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            // .{ .name = "msdfgen", .module = msdfgen },
            .{ .name = "msdfgen", .module = zmsdfgen },
            .{ .name = "msdfgenold", .module = msdfgen },
        },
    });
    const example_exe = b.addExecutable(.{
        .name = "example",
        .root_module = example_mod,
        .optimize = optimize,
    });
    b.installArtifact(example_exe);

    const run_example = b.addRunArtifact(example_exe);
    const run_step = b.step("run", "Run the example");
    run_step.dependOn(&run_example.step);
    run_step.dependOn(b.getInstallStep());

    const test_exe = b.addTest(.{
        .root_module = zmsdfgen,
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run the tests");
    test_step.dependOn(&test_exe.step);
}
