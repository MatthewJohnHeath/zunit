const std = @import("std");
const testing = std.testing;
const quantity = @import("quantity.zig");
const Fraction = @import("comptime_fraction.zig").Fraction;

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
pub const degree = Degree.times;

pub const Bi = quantity.IntPrefix(2);
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

pub const Tonne = Kilo.Times(Kilogram);
pub const Gram = Milli.Times(Kilogram);
pub const Litre = Deci.Times(Metre).ToThe(3);

pub const DegreeCelsius = Kelvin.OffsetBy(Fraction.init(27315, 100));
pub const DegreeFahrenheit = DegreeCelsius.OffestBy(Fraction.fromInt(-32)).TimesFraction(Fraction.init(5,9));
