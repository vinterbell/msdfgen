//! Full signed distance field transformation specifies both spatial transformation (Projection)
//! as well as distance value transformation (DistanceMapping).
const SDFTransformation = @This();

const std = @import("std");
const msdfgen = @import("root.zig");

projection: msdfgen.Projection,
distance_mapping: msdfgen.DistanceMapping,

pub fn init(
    projection: msdfgen.Projection,
    distance_mapping: msdfgen.DistanceMapping,
) SDFTransformation {
    return .{
        .projection = projection,
        .distance_mapping = distance_mapping,
    };
}

/// Converts the shape coordinate to pixel coordinate.
pub fn project(self: SDFTransformation, coord: msdfgen.Vector2) msdfgen.Vector2 {
    return self.projection.project(coord);
}

/// Converts the pixel coordinate to shape coordinate.
pub fn unproject(self: SDFTransformation, coord: msdfgen.Vector2) msdfgen.Vector2 {
    return self.projection.unproject(coord);
}

/// Converts the vector to pixel coordinate space.
pub fn projectVector(self: SDFTransformation, vector: msdfgen.Vector2) msdfgen.Vector2 {
    return self.projection.projectVector(vector);
}

/// Converts the vector from pixel coordinate space.
pub fn unprojectVector(self: SDFTransformation, vector: msdfgen.Vector2) msdfgen.Vector2 {
    return self.projection.unprojectVector(vector);
}

/// Converts the X-coordinate from shape to pixel coordinate space.
pub fn projectX(self: SDFTransformation, x: f64) f64 {
    return self.projection.projectX(x);
}

/// Converts the Y-coordinate from shape to pixel coordinate space.
pub fn projectY(self: SDFTransformation, y: f64) f64 {
    return self.projection.projectY(y);
}

/// Converts the X-coordinate from pixel to shape coordinate space.
pub fn unprojectX(self: SDFTransformation, x: f64) f64 {
    return self.projection.unprojectX(x);
}

/// Converts the Y-coordinate from pixel to shape coordinate space.
pub fn unprojectY(self: SDFTransformation, y: f64) f64 {
    return self.projection.unprojectY(y);
}
