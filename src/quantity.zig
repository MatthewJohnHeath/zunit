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

const one = factorization.primeFactorization(1);

pub fn BaseUnit(name: []const u8) type {
    return Unit(BaseUnitFactor.fromBase(name), one, FloatFactor.one);
}

pub fn FractionalPrefix(numerator: comptime_int, denominator: comptime_int) type {
    return Unit(BaseUnitFactor.one, factorization.fractionInPrimes(Fraction.init(numerator, denominator)), FloatFactor.one);
}

pub fn IntPrefix(number: comptime_int) type {
    return FractionalPrefix(Fraction.fromInt(number));
}

pub fn FloatPrefix(number: comptime_float) type {
    return Unit(BaseUnit.one, one, FloatFactor.fromBase(number));
}

fn Unit(comptime base_units_in: anytype, comptime prime_powers_in: anytype, comptime float_powers_in: anytype) type {
    return struct {
        const base_units = base_units_in;
        const prime_powers = prime_powers_in;
        const float_powers = float_powers_in;
        const Outer = @This();

        pub fn Times(Other: type) type {
            return Unit(
                base_units.mul(Other.base_units),
                prime_powers.mul(Other.prime_powers),
                float_powers.mul(Other.float_powers),
            );
        }

        pub const Reciprocal = ToThe(-1);

        pub fn Per(Other: type) type {
            return Times(Other.Reciprocal);
        }

        pub fn Pow(power: Fraction) type {
            return Unit(base_units.pow(power), prime_powers.pow(power), float_powers.pow(power));
        }

        pub fn ToThe(power: comptime_int) type {
            return Pow(Fraction.fromInt(power));
        }

        pub fn Root(power: comptime_int) type {
            return Pow(Fraction.fromInt(power).reciprocal());
        }

        pub fn OffsetBy(offset: Fraction) type {
            return OffsetUnit(@This(), offset);
        }

        pub fn times(value: anytype) Of(@TypeOf(value)) {
            return .{ .value = value };
        }

        pub fn Of(Scalar: type) type {
            return struct {
                value: Scalar,

                const Self = @This();
                pub const UnitType = Outer;

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

                pub fn eql(self: Self, other: anytype) bool {
                    assertSameUnits(other, "eql");
                    return self.value == other.value;
                }

                pub fn neql(self: Self, other: anytype) bool {
                    assertSameUnits(other, "neql");
                    return !self.eql(other);
                }

                pub fn lt(self: Self, other: anytype) bool {
                    assertSameUnits(other, "lt");
                    return self.value < other.value;
                }

                pub fn gt(self: Self, other: anytype) bool {
                    assertSameUnits(other, "gt");
                    return other.lt(self);
                }

                pub fn le(self: Self, other: anytype) bool {
                    assertSameUnits(other, "le");
                    return !self.gt(other);
                }

                pub fn ge(self: Self, other: anytype) bool {
                    assertSameUnits(other, "ge");
                    return !self.lt(other);
                }

                pub fn neg(self: Self) Self {
                    return .{
                        .value = -self.value,
                    };
                }

                pub fn add(self: Self, other: anytype) Of(@TypeOf(self.value, other.value)) {
                    assertSameUnits(other, "add");
                    return .{
                        .value = self.value + other.value,
                    };
                }

                pub fn sub(self: Self, other: anytype) Of(@TypeOf(self.value, other.value)) {
                    assertSameUnits(other, "sub");
                    return .{
                        .value = self.value - other.value,
                    };
                }
                pub const diff = sub;

                fn MulType(Other: type) type {
                    const self: Self = undefined;
                    const other: Other = undefined;
                    return Times(Other.UnitType).Of(@TypeOf(self.value, other.value));
                }

                pub fn mul(self: Self, other: anytype) MulType(@TypeOf(other)) {
                    return .{ .value = self.value * other.value };
                }

                pub fn reciprocal(self: Self) Reciprocal.Of(Scalar) {
                    return .{ .value = 1.0 / self.value };
                }

                pub fn div(self: Self, other: anytype) MulType(@TypeOf(other).Reciprocal) {
                    return .{ .value = self.value / other.value };
                }

                pub fn pow(self: Self, power: Fraction) Pow(power).Quanity(Scalar) {
                    return .{ .value = std.math.pow(@TypeOf(self.value), self.value, power.toFloat()) };
                }

                pub fn powi(self: Self, power: comptime_int) ToThe(power).Quanity(Scalar) {
                    return self.pow(Fraction.fromInt(power));
                }

                pub fn root(self: Self, power: comptime_int) Root(power).Quanity(Scalar) {
                    return self.pow(Fraction.fromInt(power).reciprocal());
                }

                fn fromAbsolute(self: Self) Self {
                    return self;
                }
                const Absolute = Self;

                pub fn convert(self: Self, OtherType: type) OtherType {
                    const QuotientType = Self.Per(OtherType.Absolute);
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
const Degree32 = Unit(radian, one_over_180, pi).Of(f32);
const Degree16 = Unit(radian, one_over_180, pi).Of(f16);

const metre = BaseUnitFactor.fromBase("metre");
const f_one = FloatFactor.one;
const Metre32 = Unit(metre, one, f_one).Of(f32);

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

// test "Times" {
//     try testing.expect(Metre32.Times(Degree32) == MetreDegree32);
//     try testing.expect(Degree32.Times(Metre32) == MetreDegree32);
// }

test "mul" {
    const two_metres = Metre32.init(2.0);
    const three_degrees = Degree32.init(3.0);
    const six_degree_metres = MetreDegree32.init(6.0);

    try testing.expect(two_metres.mul(three_degrees).eql(six_degree_metres));
}

const PerDegree32 = Unit(radian.reciprocal(), factorization.primeFactorization(180), pi.reciprocal()).Of(f32);

// test "Reciprocal" {
//     try testing.expect(Degree32.Reciprocal == PerDegree32);
// }

test "reciprocal" {
    const two_degrees = Degree32.init(2.0);
    const half_per_degree = PerDegree32.init(0.5);
    try testing.expect(two_degrees.reciprocal().eql(half_per_degree));
}

// const MetrePerDegree32 = Unit(f32, metre.div(radian), one_over_180.reciprocal(), pi.reciprocal());

// test "Per" {
//     try testing.expect(Metre32.Per(Degree32) == MetrePerDegree32);
//     try testing.expect(Metre32.Per(MetrePerDegree32) == Degree32);
// }

// test "div" {
//     const one_metre = Metre32.init(1.0);
//     const two_degrees = Degree32.init(2.0);
//     const half_metre_per_degree = MetrePerDegree32.init(0.5);
//     try testing.expect(one_metre.div(two_degrees).eql(half_metre_per_degree));
// }

// const two = Fraction.fromInt(2);
// const MetrePerDegreeAllSquared32 = Unit(f32, metre.div(radian).pow(two), one_over_180.reciprocal().pow(two), pi.reciprocal().pow(two));
// const half = Fraction.init(1, 2);
// const RootMetrePerDegree32 = Unit(f32, metre.div(radian).pow(half), one_over_180.reciprocal().pow(half), pi.reciprocal().pow(half));
// const three_halves = Fraction.init(3, 2);
// const RootMetrePerDegreeAllCubed32 =
//     Unit(f32, metre.div(radian).pow(three_halves), one_over_180
//     .reciprocal().pow(three_halves), pi.reciprocal().pow(three_halves));

// test "Pow" {
//     try testing.expect(MetrePerDegree32.Pow(two) == MetrePerDegreeAllSquared32);
//     try testing.expect(MetrePerDegree32.Pow(half) == RootMetrePerDegree32);
//     try testing.expect(MetrePerDegreeAllSquared32.Pow(half) == MetrePerDegree32);
//     try testing.expect(RootMetrePerDegree32.Pow(two) == MetrePerDegree32);
//     try testing.expect(MetrePerDegree32.Pow(three_halves) == RootMetrePerDegreeAllCubed32);
// }

// test "pow" {
//     try testing.expect(MetrePerDegree32.init(2.0).pow(two).eql(MetrePerDegreeAllSquared32.init(4.0)));
//     try testing.expect(MetrePerDegree32.init(4.0).pow(three_halves).eql(RootMetrePerDegreeAllCubed32.init(8.0)));
// }

// test "ToThe" {
//     try testing.expect(MetrePerDegree32.ToThe(2) == MetrePerDegreeAllSquared32);
//     try testing.expect(RootMetrePerDegree32.ToThe(2) == MetrePerDegree32);
// }

// test "powi" {
//     try testing.expect(MetrePerDegree32.init(2.0).powi(2).eql(MetrePerDegreeAllSquared32.init(4.0)));
// }

// test "Root" {
//     try testing.expect(MetrePerDegreeAllSquared32.Root(2) == MetrePerDegree32);
//     try testing.expect(MetrePerDegree32.Root(2) == RootMetrePerDegree32);
// }

// test "root" {
//     try testing.expect(MetrePerDegreeAllSquared32.init(4.0).root(2).eql(MetrePerDegree32.init(2.0)));
// }

// test "convert" {
//     const Radian32 = Unit(f32, radian, one, f_one);
//     const epsilon = 0.0000001;
//     try testing.expect(std.math.approxEqAbs(f32, Degree32.init(180.0).convert(Radian32).value, Radian32.init(std.math.pi).value, epsilon));
// }
