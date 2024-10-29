const std = @import("std");
const testing = std.testing;
const quantity = @import("quantity.zig");

pub const Metre = quantity.BaseUnit("metre");

pub const metres = Metre.times;

test "metres" {
    const two: f32 = 2.0;
    const two_metres = metres(two);
    try testing.expect(two_metres.value == two);
    try testing.expect(@TypeOf(two_metres) == Metre.Of(f32));
}

pub const Second = quantity.BaseUnit("second");

pub const Kilogram = quantity.BaseUnit("kilogram");

pub const Ampere = quantity.BaseUnit("ampere");

pub const Kelvin = quantity.BaseUnit("kelvin");

pub const Mole = quantity.BaseUnit("mole");

pub const Candela = quantity.BaseUnit("candela");

pub const Radian = quantity.BaseUnit("radian");

pub const Rot = Radian.Times(quantity.FloatPrefix(2.0 * std.math.pi));

pub const Degree = Rot.Times(quantity.IntPrefix(360).reciprocal());

pub const Pixel = quantity.BaseUnit("pixel");

pub const Bit = quantity.BaseUnit("bit");

const Bi = quantity.IntPrefix(2);

const Octo = Bi.ToThe(3);

pub const Byte = Octo.Times(Bit);
