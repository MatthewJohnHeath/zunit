const std = @import("std");
const testing = std.testing;
const quantity = @import("quantity.zig");
const Fraction = @import("comptime_fraction.zig").ComptimeFraction;

pub const Metre = quantity.BaseUnit("metre");
pub const metres = Metre.times;

test "metres" {
    const two: f32 = 2.0;
    const two_metres = metres(two);
    try testing.expect(two_metres.value == two);
    try testing.expect(@TypeOf(two_metres) == Metre.Of(f32));
}

pub const Second = quantity.BaseUnit("second");
pub const seconds = Second.times;

pub const Kilogram = quantity.BaseUnit("kilogram");
pub const kilograms = Kilogram.times;

pub const Ampere = quantity.BaseUnit("ampere");
pub const amperes = Ampere.times;

pub const Kelvin = quantity.BaseUnit("kelvin");
pub const kelvins = Kelvin.times;

pub const Mole = quantity.BaseUnit("mole");
pub const moles = Mole.times;

pub const Candela = quantity.BaseUnit("candela");
pub const candelas = Candela.times;

pub const Radian = quantity.BaseUnit("radian");
pub const radians = Radian.times;
pub const Rot = Radian.Times(quantity.FloatPrefix(2.0 * std.math.pi));
pub const rot = Rot.times;
pub const Degree = Rot.Times(quantity.IntPrefix(360).Reciprocal);
pub const degrees = Degree.times;

test "degrees" {
    const epsilon = 0.0000001;
    try testing.expect(std.math.approxEqAbs(f32, degrees(180.0).convert(Radian.Of(f32)).value, std.math.pi, epsilon));
}

pub const Bi = quantity.PrimePrefix(2);
pub const Octo = Bi.ToThe(3);
pub const Kibi = Bi.ToThe(10);
pub const Mebi = Kibi.ToThe(2);
pub const Gibi = Kibi.ToThe(3);
pub const Tebi = Kibi.ToThe(4);
pub const Semi = Bi.Reciprocal;

pub const Deca = quantity.IntPrefix(10);
pub const Deci = Deca.Reciprocal;
pub const Hecto = Deca.ToThe(2);
pub const Centi = Hecto.Reciprocal;
pub const Kilo = Deca.ToThe(3);
pub const Milli = Kilo.Reciprocal;
pub const Mega = Deca.ToThe(6);
pub const Micro = Mega.Reciprocal;
pub const Giga = Deca.ToThe(9);
pub const Nano = Giga.Reciprocal;
pub const Tera = Deca.ToThe(12);
pub const Pico = Tera.Reciprocal;
pub const Peta = Deca.ToThe(15);
pub const Femto = Peta.Reciprocal;

pub const Pixel = quantity.BaseUnit("pixel");
pub const pixels = Pixel.times;
pub const Bit = quantity.BaseUnit("bit");
pub const bits = Bit.times;
pub const Byte = Octo.Times(Bit);
pub const bytes = Byte.times;
test "bytes" {
    try testing.expect(bytes(1.0).convert(Bit.Of(f32)).eql(bits(8.0)));
}

pub const Tonne = Kilo.Times(Kilogram);
pub const Gram = Milli.Times(Kilogram);
pub const Litre = Deci.Times(Metre).ToThe(3);

pub const DegreeCelsius = Kelvin.OffsetBy(Fraction.init(27315, 100));
pub const DegreeFahrenheit = DegreeCelsius.TimesFraction(Fraction.init(5, 9)).OffsetBy(Fraction.fromInt(-32));

test "boiling point of water" {
    const epsilon = 0.0000001;
    try testing.expect(std.math.approxEqAbs(f64, DegreeCelsius.times(100.0).convert(DegreeFahrenheit.Of(f64)).value, 212.0, epsilon));
    try testing.expect(DegreeFahrenheit.times(212.0).convert(DegreeCelsius.Of(f64)).eql(DegreeCelsius.times(100.0)));
    try testing.expect(DegreeFahrenheit.times(212.0).convert(Kelvin.Of(f64)).eql(Kelvin.times(373.15)));
}
