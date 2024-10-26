const std = @import("std");
const testing = std.testing;
const factorization = @import("factorization.zig");
const compare = @import("compare.zig");
const fraction = @import("comptime_fraction.zig");

const Fraction = fraction.ComptimeFraction;

fn Quantity(comptime ScalarType: type, comptime base_units_in: anytype, comptime prime_powers_in: anytype, comptime float_powers_in: anytype) type {
    return struct {
        value: ScalarType,

        const base_units = base_units_in;
        const prime_powers = prime_powers_in;
        const float_powers = float_powers_in;
        const Self = @This();
        const Scalar = ScalarType;

        pub fn init(val: Scalar) Self {
            return Self{ .value = val };
        }

        pub fn eq(this: Self, other: Self) bool {
            return this.value == other.value;
        }

        pub fn neq(this: Self, other: Self) bool {
            return !this.eq(other);
        }

        pub fn lt(this: Self, other: Self) bool {
            return this.value < other.value;
        }

        pub fn gt(this: Self, other: Self) bool {
            return other.lt(this);
        }

        pub fn le(this: Self, other: Self) bool {
            return !this.gt(other);
        }

        pub fn ge(this: Self, other: Self) bool {
            return !this.lt(other);
        }

        pub fn neg(this: Self) Self {
            return Self{
                .value = -this.value,
            };
        }

        pub fn add(this: Self, other: Self) Self {
            return .{
                .value = this.value + other.value,
            };
        }

        pub fn sub(this: Self, other: Self) Self {
            return .{
                .value = this.value - other.value,
            };
        }

        pub fn Times(Other: type) type {
            const other: Other = undefined;
            const self: Self = undefined;
            return Quantity(
                @TypeOf(self.value, other.value),
                base_units.mul(Other.base_units),
                prime_powers.mul(Other.prime_powers),
                float_powers.mul(Other.float_powers),
            );
        }

        pub fn mul(this: Self, other: anytype) Times(@TypeOf(other)) {
            return .{ .value = this.value * other.value };
        }

        pub const Reciprocal = ToThe(-1);

        pub fn reciprocal(self: Self) Reciprocal {
            return Reciprocal{ .value = 1.0 / self.value };
        }

        pub fn Per(Other: type) type {
            return Times(Other.Reciprocal);
        }

        pub fn div(this: Self, other: anytype) Per(@TypeOf(other)) {
            return .{ .value = this.value / other.value };
        }

        pub fn Pow(power: Fraction) type {
            return Quantity(Scalar, base_units.pow(power), prime_powers.pow(power), float_powers.pow(power));
        }

        pub fn pow(self: Self, power: Fraction) Pow(power) {
            return .{ .value = std.math.pow(@TypeOf(self.value), self.value, power.toFloat()) };
        }

        pub fn ToThe(power: comptime_int) type {
            return Pow(Fraction.fromInt(power));
        }

        pub fn powi(self: Self, power: comptime_int) ToThe(power) {
            return self.pow(Fraction.fromInt(power));
        }

        pub fn Root(power: comptime_int) type {
            return Pow(Fraction.fromInt(power).reciprocal());
        }

        pub fn root(self: Self, power: comptime_int) Root(power) {
            return self.pow(Fraction.fromInt(power).reciprocal());
        }
    };
}

const BaseUnit = factorization.Factorization(1, []const u8, compare.string_before, compare.string_eql);
const float_compare = compare.NumberCompare(comptime_float);
const FloatFactor = factorization.Factorization(1, comptime_float, float_compare.before, float_compare.eql);

const radian = BaseUnit.fromBase("radian");
const one_over_360 = factorization.primeFactorization(180).reciprocal();
const pi = FloatFactor.fromBase(std.math.pi);
const Degree32 = Quantity(f32, radian, one_over_360, pi);

test "eq" {
    const oneDegree = Degree32.init(1.0);
    const twoDegrees = Degree32.init(2.0);

    try testing.expect(oneDegree.eq(oneDegree));
    try testing.expect(!oneDegree.eq(twoDegrees));
}

test "neq" {
    const oneDegree = Degree32.init(1.0);
    const twoDegrees = Degree32.init(2.0);

    try testing.expect(!oneDegree.neq(oneDegree));
    try testing.expect(oneDegree.neq(twoDegrees));
}

test "lt" {
    const oneDegree = Degree32.init(1.0);
    const twoDegrees = Degree32.init(2.0);

    try testing.expect(oneDegree.lt(twoDegrees));
    try testing.expect(!twoDegrees.lt(oneDegree));
    try testing.expect(!oneDegree.lt(oneDegree));
}

test "gt" {
    const oneDegree = Degree32.init(1.0);
    const twoDegrees = Degree32.init(2.0);

    try testing.expect(!oneDegree.gt(twoDegrees));
    try testing.expect(twoDegrees.gt(oneDegree));
    try testing.expect(!oneDegree.gt(oneDegree));
}

test "le" {
    const oneDegree = Degree32.init(1.0);
    const twoDegrees = Degree32.init(2.0);

    try testing.expect(oneDegree.le(twoDegrees));
    try testing.expect(!twoDegrees.le(oneDegree));
    try testing.expect(oneDegree.le(oneDegree));
}

test "ge" {
    const oneDegree = Degree32.init(1.0);
    const twoDegrees = Degree32.init(2.0);

    try testing.expect(!oneDegree.ge(twoDegrees));
    try testing.expect(twoDegrees.ge(oneDegree));
    try testing.expect(oneDegree.ge(oneDegree));
}

test "neg" {
    const oneDegree = Degree32.init(1.0);
    const minusOneDegree = Degree32.init(-1.0);

    try testing.expect(oneDegree.neg().eq(minusOneDegree));
    try testing.expect(minusOneDegree.neg().eq(oneDegree));
}

test "add" {
    const oneDegree = Degree32.init(1.0);
    const twoDegrees = Degree32.init(2.0);
    const threeDegrees = Degree32.init(3.0);

    const sum = oneDegree.add(twoDegrees);

    try testing.expect(sum.eq(threeDegrees));
}

test "sub" {
    const oneDegree = Degree32.init(1.0);
    const twoDegrees = Degree32.init(2.0);
    const minusOneDegree = Degree32.init(-1.0);

    const difference = oneDegree.sub(twoDegrees);

    try testing.expect(difference.eq(minusOneDegree));
}

const metre = BaseUnit.fromBase("radian");
const one = factorization.primeFactorization(1);
const f_one = FloatFactor.one;
const Metre32 = Quantity(f32, metre, one, f_one);
const metre_radian = metre.mul(radian);
const MetreDegree32 = Quantity(f32, metre_radian, one_over_360, pi);

test "Times" {
    try testing.expect(Metre32.Times(Degree32) == MetreDegree32);
    try testing.expect(Degree32.Times(Metre32) == MetreDegree32);
}

test "mul" {
    const two_metres = Metre32.init(2.0);
    const three_degrees = Degree32.init(3.0);
    const six_degree_metres = MetreDegree32.init(6.0);

    try testing.expect(two_metres.mul(three_degrees).eq(six_degree_metres));
}

const PerDegree32 = Quantity(f32, radian.reciprocal(), factorization.primeFactorization(180), pi.reciprocal());

test "Reciprocal" {
    try testing.expect(Degree32.Reciprocal == PerDegree32);
}

test "reciprocal" {
    const two_degrees = Degree32.init(2.0);
    const half_per_degree = PerDegree32.init(0.5);
    try testing.expect(two_degrees.reciprocal().eq(half_per_degree));
}

const MetrePerDegree32 = Quantity(f32, metre.div(radian), one_over_360.reciprocal(), pi.reciprocal());

test "Per" {
    try testing.expect(Metre32.Per(Degree32) == MetrePerDegree32);
    try testing.expect(Metre32.Per(MetrePerDegree32) == Degree32);
}

test "div" {
    const one_metre = Metre32.init(1.0);
    const two_degrees = Degree32.init(2.0);
    const half_metre_per_degree = MetrePerDegree32.init(0.5);
    try testing.expect(one_metre.div(two_degrees).eq(half_metre_per_degree));
}

const two = Fraction.fromInt(2);
const MetrePerDegreeAllSquared32 = Quantity(f32, metre.div(radian).pow(two), one_over_360.reciprocal().pow(two), pi.reciprocal().pow(two));
const half = Fraction.init(1, 2);
const RootMetrePerDegree32 = Quantity(f32, metre.div(radian).pow(half), one_over_360.reciprocal().pow(half), pi.reciprocal().pow(half));
const three_halves = Fraction.init(3, 2);
const RootMetrePerDegreeAllCubed32 =
    Quantity(f32, metre.div(radian).pow(three_halves), one_over_360.reciprocal().pow(three_halves), pi.reciprocal().pow(three_halves));

test "Pow" {
    try testing.expect(MetrePerDegree32.Pow(two) == MetrePerDegreeAllSquared32);
    try testing.expect(MetrePerDegree32.Pow(half) == RootMetrePerDegree32);
    try testing.expect(MetrePerDegreeAllSquared32.Pow(half) == MetrePerDegree32);
    try testing.expect(RootMetrePerDegree32.Pow(two) == MetrePerDegree32);
    try testing.expect(MetrePerDegree32.Pow(three_halves) == RootMetrePerDegreeAllCubed32);
}

test "pow" {
    try testing.expect(MetrePerDegree32.init(2.0).pow(two).eq(MetrePerDegreeAllSquared32.init(4.0)));
    try testing.expect(MetrePerDegree32.init(4.0).pow(three_halves).eq(RootMetrePerDegreeAllCubed32.init(8.0)));
}

test "ToThe" {
    try testing.expect(MetrePerDegree32.ToThe(2) == MetrePerDegreeAllSquared32);
    try testing.expect(RootMetrePerDegree32.ToThe(2) == MetrePerDegree32);
}

test "powi" {
    try testing.expect(MetrePerDegree32.init(2.0).powi(2).eq(MetrePerDegreeAllSquared32.init(4.0)));
}

test "Root" {
    try testing.expect(MetrePerDegreeAllSquared32.Root(2) == MetrePerDegree32);
    try testing.expect(MetrePerDegree32.Root(2) == RootMetrePerDegree32);
}

test "root" {
    try testing.expect(MetrePerDegreeAllSquared32.init(4.0).root(2).eq(MetrePerDegree32.init(2.0)));
}

pub fn Units(FloatType: type) type {
    return struct {
        pub fn BaseQuantity(name: []const u8) type {
            return Quantity(FloatType, BaseUnit.fromBase(name), one, FloatFactor.one);
        }

        pub fn FractionalPrefix(numerator: comptime_int, denominator: comptime_int) type {
            return Quantity(FloatType, BaseUnit.one, factorization.fractionInPrimes(Fraction.init(numerator, denominator)), FloatFactor.one);
        }

        pub fn IntPrefix(number: comptime_int) type {
            return Quantity(FloatType, BaseUnit.one, factorization.primeFactorization(number), FloatFactor.one);
        }

        pub fn FloatPrefix(number: comptime_float) type {
            return Quantity(FloatType, BaseUnit.one, one, FloatFactor.fromBase(number));
        }
    };
}
