const std = @import("std");
const testing = std.testing;
const quantity = @import("quantity.zig");

const Units = quantity.Units;

pub fn Metre(Scalar: type) type {
    return Units(Scalar).BaseQuantity("metre");
}

test "Metre" {
    try testing.expect((Metre(f16) == Units(f16).BaseQuantity("metre")));
}
