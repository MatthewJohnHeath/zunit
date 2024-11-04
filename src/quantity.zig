const std = @import("std");
const testing = std.testing;
const factorization = @import("factorization.zig");
const compare = @import("compare.zig");
const fraction = @import("comptime_fraction.zig");

const Fraction = fraction.ComptimeFraction;
const OffsetUnit = @import("offset_quantity.zig").OffsetUnit;
const BaseUnitFactor = factorization.Factorization(1, []const u8, compare.string_before, compare.string_eql);
const float_compare = compare.NumberCompare(comptime_float);
const FloatFactor = factorization.Factorization(1, comptime_float, float_compare.before, float_compare.eql);
const int_compare = compare.NumberCompare(comptime_int);
const IntFactor = factorization.Factorization(1, comptime_int, int_compare.before, int_compare.eql);


/// Dimensionless, unscaled unit type. 
pub const One = Unit(BaseUnitFactor.one, IntFactor.one, FloatFactor.one);

/// Creates a new base limit from a name. 
pub fn BaseUnit(name: []const u8) type {
    return Unit(BaseUnitFactor.fromBase(name), IntFactor.one, FloatFactor.one);
}

/// Creates a factorization in prime factors from a fraction. The fraction must be positive and known at compile time.
fn FractionalPrefixFromFraction(frac: Fraction) type {
    return Unit(BaseUnitFactor.one, factorization.fractionInPrimes(frac), FloatFactor.one);
}

/// Creates a factorization in prime factors from the numerator and denominator of a fraction. The fraction must be positive and known at compile time.
pub fn FractionalPrefix(numerator: comptime_int, denominator: comptime_int) type {
    return FractionalPrefixFromFraction(Fraction.init(numerator, denominator));
}

/// Creates a factorization in prime factors from a comptime_int. The number must be positive and known at compile time.
pub fn IntPrefix(number: comptime_int) type {
    return FractionalPrefixFromFraction(Fraction.fromInt(number));
}

/// Creates an integer factorization containing the given comptime_int to the power 1. 
/// Designed to be used when "number" is prime. Will not compile if "number" is not positive.
pub fn PrimePrefix(number: comptime_int) type {
    comptime{
        if(number <= 0){
            @compileError("Only positive integers can be used to create PrimePrefix.");
        }
    }
    return Unit(BaseUnitFactor.one, IntFactor.fromBase(number), FloatFactor.one);
}

/// Creates a float factorization containing the given number to the power 1. 
/// Designed to be used when "number" not a rational power of a rational numer (e.g. pi).
/// Will not compile if "number" is not positive.
pub fn FloatPrefix(number: comptime_float) type {
    comptime{
        if(number <= 0.0){
            @compileError("Only positive floats can be used to create FloatPrefix.");
        }
    }
    return Unit(BaseUnitFactor.one, IntFactor.one, FloatFactor.fromBase(number));
}

/// Creates the type representing a unit as a prodcut of powers of base units, prime numbers and floats.
/// Requires: 
///     - base_units_in of type factorization.Factorization(SIZE, []const u8, compare.string_before, compare.string_eql) for some SIZE ,
///       with the base strings in increasing order.
///     - prime_powers_in of type factorization.Factorization(SIZE, comptime_int, int_compare.before, int_compare.eql) for some SIZE ,
///       with the base integers in increasing order.
///     - float_powers_in of type factorization.Factorization(SIZE, comptime_float, float_compare.before, float_compare.eql) for some SIZE ,
///       with the base floats in increasing order.
fn Unit(comptime base_units_in: anytype, comptime prime_powers_in: anytype, comptime float_powers_in: anytype) type {
    return struct {
        const base_units = base_units_in;
        const prime_powers = prime_powers_in;
        const float_powers = float_powers_in;
        const Outer = @This();

        /// Makes the unit a quantity of this unit multiplied by a quanity of unit Other.
        pub fn Times(Other: type) type {
            return Unit(
                base_units.mul(Other.base_units),
                prime_powers.mul(Other.prime_powers),
                float_powers.mul(Other.float_powers),
            );
        }

        /// The unit of the reciprocal of a quanitity of this unit. 
        pub const Reciprocal = ToThe(-1);

        /// Makes the unit a quantity of this unit divided multiplied by a quanity of unit Other.
        pub fn Per(Other: type) type {
            return Times(Other.Reciprocal);
        }

        /// Scales this unit by a fraction.
        pub fn TimesFraction(multiplier: Fraction) type {
            return Times(FractionalPrefixFromFraction(multiplier));
        }

        /// Raises this unit to a fractional power.
        pub fn Pow(power: Fraction) type {
            return Unit(base_units.pow(power), prime_powers.pow(power), float_powers.pow(power));
        }

        /// Raises this unit to a integer power.
        pub fn ToThe(power: comptime_int) type {
            return Pow(Fraction.fromInt(power));
        }

        /// Takes the power-th root of this unit.
        pub fn Root(power: comptime_int) type {
            return Pow(Fraction.fromInt(power).reciprocal());
        }

        /// Creates an OffsetUnit with the current unit as the base unit and given offest.
        pub fn OffsetBy(offset: Fraction) type {
            return OffsetUnit(@This(), offset);
        }

        /// Makes the quantity with value of the current unit.
        pub fn times(value: anytype) Of(@TypeOf(value)) {
            return .{ .value = value };
        }

        /// Makes the type of a quantity with the current unit and the given float type as the scalar.
        pub fn Of(Scalar: type) type {
            return struct {
                /// The number of units.
                value: Scalar,

                const Self = @This();
                /// The units of the current quantity.
                pub const UnitType = Outer;

                /// Creates a quantity.
                pub fn init(val: Scalar) Self {
                    return .{ .value = val };
                }

                fn sameUnits(Other: type) bool {
                    return UnitType == Other.UnitType;
                }

                fn assertSameUnits(other: anytype, comptime function_name: []const u8) void {
                    if (!comptime sameUnits(@TypeOf(other))) {
                        @compileError("It is not permitted to call " ++ function_name ++ " except on Unit types with the same units");
                    }
                }

                /// Equals.
                pub fn eql(self: Self, other: anytype) bool {
                    assertSameUnits(other, "eql");
                    return self.value == other.value;
                }

                /// Not equals.
                pub fn neql(self: Self, other: anytype) bool {
                    assertSameUnits(other, "neql");
                    return !self.eql(other);
                }

                /// Less than.
                pub fn lt(self: Self, other: anytype) bool {
                    assertSameUnits(other, "lt");
                    return self.value < other.value;
                }

                /// Greater than.
                pub fn gt(self: Self, other: anytype) bool {
                    assertSameUnits(other, "gt");
                    return other.lt(self);
                }

                /// Less than or equal.
                pub fn le(self: Self, other: anytype) bool {
                    assertSameUnits(other, "le");
                    return !self.gt(other);
                }

                /// Greater than.
                pub fn ge(self: Self, other: anytype) bool {
                    assertSameUnits(other, "ge");
                    return !self.lt(other);
                }

                /// Negation.
                pub fn neg(self: Self) Self {
                    return .{
                        .value = -self.value,
                    };
                }

                /// Absolute value.
                pub fn abs(self: Self) Self {
                    return .{
                        .value = @abs(self.value),
                    };
                }

                /// Adds a quantity with the same units. 
                pub fn add(self: Self, other: anytype) Of(@TypeOf(self.value, other.value)) {
                    assertSameUnits(other, "add");
                    return .{
                        .value = self.value + other.value,
                    };
                }

                /// Subtracts a quantity with the same units. 
                pub fn sub(self: Self, other: anytype) Of(@TypeOf(self.value, other.value)) {
                    assertSameUnits(other, "sub");
                    return .{
                        .value = self.value - other.value,
                    };
                }

                /// Subtracts a quantity with the same units. Included for compatibiliy with OffsetUnit quantities.
                pub const diff = sub;

                fn ValueType(T: anytype) type {
                    return switch (@typeInfo(T)) {
                        .ComptimeFloat, .Float => T,
                        else => T.Scalar,
                    };
                }

                fn MulType(Other: type) type {
                    const self: Self = undefined;
                    const other: Other = undefined;
                    return switch (@typeInfo(Other)) {
                        .ComptimeFloat, .Float => Self,
                        else => Times(Other.UnitType).Of(@TypeOf(self.value, other.value)),
                    };
                }

                /// Multiplies by a Unit quantity or a float.
                pub fn mul(self: Self, other: anytype) MulType(@TypeOf(other)) {
                    const multiplier = switch (@typeInfo(@TypeOf(other))) {
                        .ComptimeFloat, .Float => other,
                        else => other.value,
                    };
                    return .{ .value = self.value * multiplier };
                }

                /// Reciprocal.
                pub fn reciprocal(self: Self) Reciprocal.Of(Scalar) {
                    return .{ .value = 1.0 / self.value };
                }

                fn DivType(Other: type) type {
                    const self: Self = undefined;
                    const other: Other = undefined;
                    return switch (@typeInfo(Other)) {
                        .ComptimeFloat, .Float => Self,
                        else => Per(Other.UnitType).Of(@TypeOf(self.value, other.value)),
                    };
                }

                /// Divides by a Unit quantity or a float.
                pub fn div(self: Self, other: anytype) DivType(@TypeOf(other)) {
                    const divisor = switch (@typeInfo(@TypeOf(other))) {
                        .ComptimeFloat, .Float => other,
                        else => other.value,
                    };
                    return .{ .value = self.value / divisor };
                }

                /// Raises quantity to a fractional power, which must be known at compile time.
                pub fn pow(self: Self, power: Fraction) Pow(power).Of(Scalar) {
                    return .{ .value = std.math.pow(@TypeOf(self.value), self.value, power.toFloat()) };
                }

                /// Raises quantity to an integer power, which must be known at compile time.
                pub fn powi(self: Self, power: comptime_int) ToThe(power).Of(Scalar) {
                    return self.pow(Fraction.fromInt(power));
                }

                /// Calculates the n-th root, for n-known at compile time.
                pub fn root(self: Self, n: comptime_int) Root(n).Of(Scalar) {
                    return self.pow(Fraction.fromInt(n).reciprocal());
                }

                fn fromAbsolute(self: Self) Self {
                    return self;
                }
                const Absolute = Self;

                /// Converts the quantity to a different type. The output type is required to a quantity of a Unit or OffsetUnit with the same base units. 
                pub fn convert(self: Self, OtherType: type) OtherType {
                    const QuotientType = UnitType.Per(OtherType.Absolute.UnitType);
                    comptime {
                        if (QuotientType.base_units.factors.len != 0) {
                            @compileError("convert can only be called between types of the same dimensions");
                        }
                    }
                    const multiple = comptime QuotientType.prime_powers.toFloat() * QuotientType.float_powers.toFloat();
                    const absolute_other = OtherType.Absolute{ .value = @floatCast(self.value * multiple) };
                    return OtherType.fromAbsolute(absolute_other);
                }
            };
        }
    };
}

const radian = BaseUnitFactor.fromBase("radian");
const one_over_180 = factorization.primeFactorization(180).reciprocal();
const pi = FloatFactor.fromBase(std.math.pi);
const Degree = Unit(radian, one_over_180, pi);

const metre = BaseUnitFactor.fromBase("metre");
const Metre = Unit(metre, IntFactor.one, FloatFactor.one);

const MetreDegree = Unit(metre.mul(radian), one_over_180, pi);

test "Times" {
    try testing.expect(Metre.Times(Degree) == MetreDegree);
    try testing.expect(Degree.Times(Metre) == MetreDegree);
}

const PerDegree = Unit(radian.reciprocal(), factorization.primeFactorization(180), pi.reciprocal());

test "Reciprocal" {
    try testing.expect(Degree.Reciprocal == PerDegree);
}

const MetrePerDegree = Unit(metre.div(radian), one_over_180.reciprocal(), pi.reciprocal());

test "Per" {
    try testing.expect(Metre.Per(Degree) == MetrePerDegree);
    try testing.expect(Metre.Per(MetrePerDegree) == Degree);
}

const two = Fraction.fromInt(2);
const MetrePerDegreeAllSquared = Unit(metre.div(radian).pow(two), one_over_180.reciprocal().pow(two), pi.reciprocal().pow(two));
const half = Fraction.init(1, 2);
const RootMetrePerDegree = Unit(metre.div(radian).pow(half), one_over_180.reciprocal().pow(half), pi.reciprocal().pow(half));
const three_halves = Fraction.init(3, 2);
const RootMetrePerDegreeAllCubed =
    Unit(metre.div(radian).pow(three_halves), one_over_180
    .reciprocal().pow(three_halves), pi.reciprocal().pow(three_halves));

test "Pow" {
    try testing.expect(MetrePerDegree.Pow(two) == MetrePerDegreeAllSquared);
    try testing.expect(MetrePerDegree.Pow(half) == RootMetrePerDegree);
    try testing.expect(MetrePerDegreeAllSquared.Pow(half) == MetrePerDegree);
    try testing.expect(RootMetrePerDegree.Pow(two) == MetrePerDegree);
    try testing.expect(MetrePerDegree.Pow(three_halves) == RootMetrePerDegreeAllCubed);
}

test "ToThe" {
    try testing.expect(MetrePerDegree.ToThe(2) == MetrePerDegreeAllSquared);
    try testing.expect(RootMetrePerDegree.ToThe(2) == MetrePerDegree);
}

test "Root" {
    try testing.expect(MetrePerDegreeAllSquared.Root(2) == MetrePerDegree);
    try testing.expect(MetrePerDegree.Root(2) == RootMetrePerDegree);
}

test "OffsetBy" {
    try testing.expect(Metre.OffsetBy(Fraction.fromInt(-2)).offset.value == -2);
    try testing.expect(Metre.OffsetBy(Fraction.fromInt(0)) == Metre);
}

test "times" {
    try testing.expect(Metre.times(2).value == 2);
}

const Metre32 = Metre.Of(f32);
const Degree32 = Degree.Of(f32);
const Degree16 = Degree.Of(f16);

test "sameUnits" {
    try testing.expect(Degree32.sameUnits(Degree16));
    try testing.expect(Degree32.sameUnits(Degree32));
    try testing.expect(!Degree32.sameUnits(Metre32));
}

test "eql" {
    const oneDegree = Degree32.init(1.0);
    try testing.expect(oneDegree.eql(oneDegree));
    try testing.expect(oneDegree.eql(Degree16.init(1.0)));
    try testing.expect(!oneDegree.eql(Degree32.init(2.0)));
    try testing.expect(!oneDegree.eql(Degree16.init(0.0)));
    // Uncommenting will caused compile error.
    // try testing.expect(!oneDegree.eql(Metre32.init(1.0)));
}

test "neql" {
    const oneDegree = Degree32.init(1.0);

    try testing.expect(!oneDegree.neql(oneDegree));
    try testing.expect(oneDegree.neql(Degree16.init(2.0)));
    try testing.expect(oneDegree.neql(Degree32.init(2.0)));
}

test "lt" {
    const oneDegree = Degree32.init(1.0);
    const twoDegrees = Degree16.init(2.0);

    try testing.expect(oneDegree.lt(twoDegrees));
    try testing.expect(oneDegree.lt(Degree16.init(2.0)));
    try testing.expect(!twoDegrees.lt(oneDegree));
    try testing.expect(!oneDegree.lt(oneDegree));
}

test "gt" {
    const oneDegree = Degree32.init(1.0);
    const twoDegrees = Degree16.init(2.0);

    try testing.expect(!oneDegree.gt(twoDegrees));
    try testing.expect(twoDegrees.gt(oneDegree));
    try testing.expect(!oneDegree.gt(oneDegree));
}

test "le" {
    const oneDegree = Degree32.init(1.0);
    const twoDegrees = Degree16.init(2.0);

    try testing.expect(oneDegree.le(twoDegrees));
    try testing.expect(!twoDegrees.le(oneDegree));
    try testing.expect(oneDegree.le(oneDegree));
}

test "ge" {
    const oneDegree = Degree32.init(1.0);
    const twoDegrees = Degree16.init(2.0);

    try testing.expect(!oneDegree.ge(twoDegrees));
    try testing.expect(twoDegrees.ge(oneDegree));
    try testing.expect(oneDegree.ge(oneDegree));
}

test "neg" {
    const oneDegree = Degree32.init(1.0);
    const minusOneDegree = Degree16.init(-1.0);

    try testing.expect(oneDegree.neg().eql(minusOneDegree));
    try testing.expect(minusOneDegree.neg().eql(oneDegree));
}

test "abs" {
    const oneDegree = Degree32.init(1.0);
    const minusOneDegree = Degree16.init(-1.0);

    try testing.expect(oneDegree.abs().eql(oneDegree));
    try testing.expect(minusOneDegree.abs().eql(oneDegree));
}

test "add" {
    const oneDegree = Degree32.init(1.0);
    const twoDegrees = Degree16.init(2.0);
    const threeDegrees = Degree32.init(3.0);

    const sum = oneDegree.add(twoDegrees);

    try testing.expect(sum.eql(threeDegrees));
}

test "sub" {
    const oneDegree = Degree32.init(1.0);
    const twoDegrees = Degree16.init(2.0);
    const minusOneDegree = Degree32.init(-1.0);

    const difference = oneDegree.sub(twoDegrees);

    try testing.expect(difference.eql(minusOneDegree));
}

const metre_radian = metre.mul(radian);
const MetreDegree32 = Unit(metre_radian, one_over_180, pi).Of(f32);

test "mul" {
    const two_metres = Metre32.init(2.0);
    const three_degrees = Degree32.init(3.0);
    const six_degree_metres = MetreDegree32.init(6.0);

    try testing.expect(two_metres.mul(three_degrees).eql(six_degree_metres));
    try testing.expect(two_metres.mul(3.0).eql(Metre32.init(6.0)));
}

test "div" {
    try testing.expect(MetreDegree32.init(6.0).div(Degree32.init(2.0)).eql(Metre32.init(3.0)));
    try testing.expect(Metre32.init(6.0).div(3.0).eql(Metre32.init(2.0)));
}

const PerDegree32 = PerDegree.Of(f32);

test "reciprocal" {
    const two_degrees = Degree32.init(2.0);
    const half_per_degree = PerDegree32.init(0.5);
    try testing.expect(two_degrees.reciprocal().eql(half_per_degree));
}

const MetrePerDegree32 = MetrePerDegree.Of(f32);
const MetrePerDegreeAllSquared32 = MetrePerDegreeAllSquared.Of(f32);
test "pow" {
    try testing.expect(MetrePerDegree32.init(2.0).pow(two).eql(MetrePerDegreeAllSquared32.init(4.0)));
    try testing.expect(MetrePerDegree32.init(4.0).pow(three_halves).eql(RootMetrePerDegreeAllCubed.Of(f32).init(8.0)));
}

test "powi" {
    try testing.expect(MetrePerDegree32.init(2.0).powi(2).eql(MetrePerDegreeAllSquared32.init(4.0)));
}

test "root" {
    try testing.expect(MetrePerDegreeAllSquared32.init(4.0).root(2).eql(MetrePerDegree32.init(2.0)));
}

test "convert" {
    const Radian32 = Unit(radian, IntFactor.one, FloatFactor.one).Of(f32);
    const epsilon = 0.0000001;
    try testing.expect(std.math.approxEqAbs(f32, Degree32.init(180.0).convert(Radian32).value, std.math.pi, epsilon));

    //convert to unit wth offset
    const InchesFromOverThere32 = Metre.TimesFraction(Fraction.init(256, 10000)).OffsetBy(Fraction.fromInt(4)).Of(f32);
    try testing.expect(std.math.approxEqAbs(f32, InchesFromOverThere32.init(1.0).convert(Metre32).value, 5.0 * 0.0256, epsilon));
}
