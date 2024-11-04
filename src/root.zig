const std = @import("std");
const testing = std.testing;
const quantity = @import("quantity.zig");

/// A rational number stored as numerator and denominator. 
pub const Fraction = @import("comptime_fraction.zig").ComptimeFraction;

/// Dimensionless, unscaled unit type. 
pub const One = quantity.One;

/// Creates a new base limit from a name. 
pub const BaseUnit = quantity.BaseUnit;

test "BaseUnit" {
    const Iguana = BaseUnit("iguana");
    const rate_of_iguanas = Iguana.times(1.0).div(seconds(0.5));
    try testing.expect(rate_of_iguanas.eql(Iguana.Per(Second).times(2.0)));
}

/// Creates a dimensionless unit type scaled by the fraction with the given  numerator and denominator. The fraction must be positive and known at compile time.
pub const FractionalPrefix = quantity.FractionalPrefix;

/// Creates a dimensionless unit type scaled by the given integer. 
/// The integer must be positive and known at compile time.
pub const IntPrefix = quantity.IntPrefix;

/// Creates a dimensionless unit type scaled by the given integer, which is intended to be prime. 
/// Using with a positive, non-prime number can result in unexpected mismatches between types.
///  Will not compile if "number" is not positive.
pub const PrimePrefix = quantity.PrimePrefix;

/// Creates a dimensionless unit type scaled by the given float. 
/// Designed to be used when "number" not a rational power of a rational number (e.g. pi). 
/// Otherwise use FractionalPrefix and call the method Root on the result.
/// Will not compile if "number" is not positive.
pub const FloatPrefix = quantity.FloatPrefix;


///--------------------------------A bunch of specifc, named units-------------------
pub const Metre = BaseUnit("metre");
pub const metres = Metre.times;
test "metres" {
    const two: f32 = 2.0;
    const two_metres = metres(two);
    try testing.expect(two_metres.value == two);
    try testing.expect(@TypeOf(two_metres) == Metre.Of(f32));
    try testing.expect(Metre.Per(One) == Metre);
    try testing.expect(metres(1.0).gt(metres(-1.0)));
    try testing.expect(Metre.Of(f16).init(2.0).eql(Metre.Of(f64).init(2.0)));
    try testing.expect(Metre.Of(f32).init(2.0).powi(3).eql(Metre.ToThe(3).times(8.0)));
}

pub const Second = BaseUnit("second");
pub const seconds = Second.times;
test "seconds" {
    const speed = metres(1.25).div(seconds(0.25));
    try testing.expect(speed.eql(Metre.Per(Second).times(5.0)));
    try testing.expect(speed.mul(2.0).eql(Metre.Per(Second).times(10.0)));
    try testing.expect(Second.Of(f32).init(4.0).root(2).eql(Second.Root(2).times(2.0)));
}

pub const Kilogram = BaseUnit("kilogram");
pub const kilograms = Kilogram.times;

pub const Ampere = BaseUnit("ampere");
pub const amperes = Ampere.times;

pub const Kelvin = BaseUnit("kelvin");
pub const kelvins = Kelvin.times;

pub const Mole = BaseUnit("mole");
pub const moles = Mole.times;

pub const Candela = BaseUnit("candela");
pub const candelas = Candela.times;

pub const Radian = BaseUnit("radian");
pub const radians = Radian.times;

pub const Rot = Radian.Times(FloatPrefix(2.0 * std.math.pi));
pub const rot = Rot.times;
pub const Degree = Rot.Times(IntPrefix(360).Reciprocal);
pub const degrees = Degree.times;

test "degrees" {
    const epsilon = 0.0000001;
    try testing.expect(std.math.approxEqAbs(f32, degrees(180.0).convert(Radian.Of(f32)).value, std.math.pi, epsilon));
}

pub const Bi = PrimePrefix(2);
pub const Semi = Bi.Reciprocal;
pub const Octo = Bi.ToThe(3);
pub const Kibi = Bi.ToThe(10);
pub const Mebi = Kibi.ToThe(2);
pub const Gibi = Kibi.ToThe(3);
pub const Tebi = Kibi.ToThe(4);

pub const Deca = IntPrefix(10);
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

pub const Pixel = BaseUnit("pixel");
pub const pixels = Pixel.times;
test "pixels" {
    try testing.expect(pixels(1.0).sub(pixels(0.5)).eql(pixels(0.5)));
    //will not compile if below is uncommented
    //try testing.expect(metres(1.0).gt(pixels(-1.0)));

}
pub const Bit = BaseUnit("bit");
pub const bits = Bit.times;
pub const Byte = Octo.Times(Bit);
pub const bytes = Byte.times;
test "bytes" {
    try testing.expect(bytes(1.0).convert(Bit.Of(f32)).eql(bits(8.0)));
    //Will not compile if the following isi uncommented
    //try testing.expect(bytes(1.0).convert(Mole.Of(f32)).eql(moles(8.0)));
}

pub const Tonne = Kilo.Times(Kilogram);
pub const tonnes = Tonne.times;
pub const Gram = Milli.Times(Kilogram);
pub const gram = Gram.times;

pub const Litre = Deci.Times(Metre).ToThe(3);
pub const litres = Litre.times;
test "litre" {
    try testing.expect(Litre == Metre.ToThe(3).Times(Milli));
    try testing.expect(Metre.ToThe(3).times(1.0).convert(Litre.Of(f32)).eql(litres(1000.0)));
}

pub const DegreeCelsius = Kelvin.OffsetBy(Fraction.init(27315, 100));
pub const degreesCelsius = DegreeCelsius.times;
pub const DegreeFahrenheit = DegreeCelsius.TimesFraction(Fraction.init(5, 9)).OffsetBy(Fraction.fromInt(-32));
pub const degreesFahrenehit = DegreeFahrenheit.times;

test "boiling point of water" {
    const epsilon = 0.0000001;
    try testing.expect(std.math.approxEqAbs(f64, degreesCelsius(100.0).convert(DegreeFahrenheit.Of(f64)).value, 212.0, epsilon));
    try testing.expect(degreesFahrenehit(212.0).convert(DegreeCelsius.Of(f64)).eql(degreesCelsius(100.0)));
    try testing.expect(degreesFahrenehit(212.0).convert(Kelvin.Of(f64)).eql(kelvins(373.15)));
}

pub const Inch = FractionalPrefix(254, 10000).Times(Metre);
pub const inches = Inch.times;

test "inch" {
    try testing.expect(inches(1.0).convert(Centi.Times(Metre).Of(f64)).eql(Centi.Times(Metre).times(2.54)));
    //will not compile if below is uncommented
    //try testing.expect(metres(1.0).lt(inches(1.0)));
}
