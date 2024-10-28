const std = @import("std");
const testing = std.testing;
const quantity = @import("quantity.zig");

const Units = quantity.Units;

pub fn Metre(Scalar: type) type {
    return Units(Scalar).BaseQuantity("metre");
}

test "Metre" {
    try testing.expect(Metre(f16) == Units(f16).BaseQuantity("metre"));
    try testing.expect(Metre(f16).init(1.0).eq(Units(f16).BaseQuantity("metre").init(1.0)));
}

pub fn metres(value: anytype) Metre(@TypeOf(value)) {
    return Metre(@TypeOf(value)).init(value);
}

test "metres" {
    const val: f32 = 1337;
    try testing.expect(metres(val).eq(Metre(f16).init(val)));
}

pub fn Second(Scalar: type) type {
    return Units(Scalar).BaseQuantity("second");
}

test "Second" {
    try testing.expect(Second(f16) == Units(f16).BaseQuantity("second"));
}

pub fn Kilogram(Scalar: type) type {
    return Units(Scalar).BaseQuantity("kilogram");
}

test "Kilogram" {
    try testing.expect(Kilogram(f16) == Units(f16).BaseQuantity("kilogram"));
}

pub fn Ampere(Scalar: type) type {
    return Units(Scalar).BaseQuantity("ampere");
}

test "Ampere" {
    try testing.expect(Ampere(f16) == Units(f16).BaseQuantity("ampere"));
}

pub fn Kelvin(Scalar: type) type {
    return Units(Scalar).BaseQuantity("kelvin");
}

test "Kelvin" {
    try testing.expect(Kelvin(f16) == Units(f16).BaseQuantity("kelvin"));
}

pub fn Mole(Scalar: type) type {
    return Units(Scalar).BaseQuantity("mole");
}

test "Mole" {
    try testing.expect(Mole(f16) == Units(f16).BaseQuantity("mole"));
}

pub fn Candela(Scalar: type) type {
    return Units(Scalar).BaseQuantity("candela");
}

test "Candela" {
    try testing.expect(Candela(f16) == Units(f16).BaseQuantity("candela"));
}

pub fn Radian(Scalar: type) type {
    return Units(Scalar).BaseQuantity("radian");
}

test "Radian" {
    try testing.expect(Radian(f16) == Units(f16).BaseQuantity("radian"));
}

pub fn Rot(Scalar: type) type {
    return Radian(Scalar).Times(Units(Scalar).FloatPrefix(2.0 * std.math.pi));
}

pub fn Degree(Scalar: type) type {
    return Rot(Scalar).Times(Units(Scalar).IntPrefix(360).reciprocal());
}
