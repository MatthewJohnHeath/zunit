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

        //     pub fn mul(this: Self, other: anytype) Times(@TypeOf(other)) {
        //         return .{ .value = this.value * other.value };
        //     }

        //     pub const Reciprocal = Pow(-1);

        //     pub fn reciprocal(self: Self) Reciprocal {
        //         return Reciprocal{ .value = 1.0 / self.value };
        //     }

        //     pub fn Per(Other: type) type {
        //         return Times(Other.Reciprocal);
        //     }

        //     pub fn div(this: Self, other: anytype) Per(@TypeOf(other)) {
        //         return .{ .value = this.value / other.value };
        //     }

        //     pub fn Pow(power: Fraction) type {
        //         return Quantity(Scalar, base_units.pow(power), prime_power_factors.pow(power), float_factors.pow(power));
        //     }

        //     pub fn pow(self: Self, power: Fraction) Pow(power) {
        //         return .{ .value = std.math.pow(self.value, power.toFloat) };
        //     }

        //     pub fn ToThe(power: comptime_int) type {
        //         return Pow(Fraction.fromInt(power));
        //     }

        //     pub fn powi(self: Self, power: comptime_int) ToThe(power) {
        //         return .{ .value = std.math.pow(self.value, power.toFloat) };
        //     }

        //     pub fn Root(power: comptime_int) type {
        //         return Pow(Fraction.init(1, power));
        //     }

        //     pub fn root(self: Self, power: comptime_int) ToThe(power) {
        //         return .{ .value = std.math.pow(self.value, 1.0 / power.toFloat) };
        //     }
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
}

// test "mul" {
//     const F32Meter = Quantity(f32, baseUnit("meter"));
//     const F32Second = Quantity(f32, baseUnit("second"));
//     const meter_second = multiplyUnits(baseUnit("meter"), baseUnit("second"));
//     const F32MeterSecond = Quantity(f32, meter_second);

//     const two_meters = F32Meter.init(2.0);
//     const three_seconds = F32Second.init(3.0);
//     const six_meter_seconds = F32MeterSecond.init(6.0);

//     try testing.expect(two_meters.mul(three_seconds).eq(six_meter_seconds));
// }

// test "mul with type resolution" {
//     const F32Meter = Quantity(f32, baseUnit("meter"));
//     const F32Second = Quantity(f16, baseUnit("second"));
//     const meter_second = multiplyUnits(baseUnit("meter"), baseUnit("second"));
//     const F32MeterSecond = Quantity(f32, meter_second);
//     const two_meters = F32Meter.init(2.0);
//     const three_seconds = F32Second.init(3.0);
//     const six_meter_seconds = F32MeterSecond.init(6.0);
//     const product = two_meters.mul(three_seconds);

//     try testing.expect(product.eq(six_meter_seconds));
//     try testing.expect(@TypeOf(product) == F32MeterSecond);
// }

// test "reciprocal" {
//     const second = baseUnit("second");
//     const twoSeconds = Quantity(f16, second).init(2.0);
//     const half_per_second = Quantity(f16, invertUnit(second)).init(0.5);
//     try testing.expect(twoSeconds.reciprocal().eq(half_per_second));
// }

// test "div" {
//     const meter = baseUnit("meter");
//     const second = baseUnit("second");
//     const per_second = invertUnit(second);
//     const meter_per_second = multiplyUnits(meter, per_second);
//     const F32Meter = Quantity(f32, meter);
//     const F16Second = Quantity(f16, second);
//     const F32MeterPerSecond = Quantity(f32, meter_per_second);
//     const three_meters = F32Meter.init(3.0);
//     const two_seconds = F16Second.init(2.0);
//     const one_point_five_mps = F32MeterPerSecond.init(1.5);
//     const quotient = three_meters.div(two_seconds);

//     try testing.expect(quotient.eq(one_point_five_mps));
//     try testing.expect(@TypeOf(quotient) == F32MeterPerSecond);
// }
