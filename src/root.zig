const std = @import("std");
const testing = std.testing;
const quantity = @import("quantity.zig");

const Units = quantity.Units;

pub fn Metre(Scalar: type) type {
    return Units(Scalar).BaseQuantity("metre");
}

test "Metre" {
    try testing.expect(Metre(f16) == Units(f16).BaseQuantity("metre"));
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
