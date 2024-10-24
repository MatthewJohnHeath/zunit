const std = @import("std");
const testing = std.testing;
const factorization = @import("factorization.zig");
const compare = @import("compare.zig");
const fraction = @import("comptime_fraction.zig");

const Fraction = fraction.ComptimeFraction;

const BaseUnitProduct = factorization.Factorization([]const u8, compare.string_before, compare.string_eql);
const PrimePowerFactors = factorization.ComptimeIntFactorization;
const float_compare = compare.NumberCompare(comptime_float);
const FloatFactors = factorization.Factorization(comptime_float, float_compare.before, float_compare.eql);

fn Quantity(comptime ScalarType: type, comptime base: BaseUnitProduct, comptime prime_powers: PrimePowerFactors, comptime floats: FloatFactors) type {
    return struct {
        value: ScalarType,

        const base_units = base;
        const prime_power_factors = prime_powers;
        const float_factors = floats;

        const Self = @This();
        const Scalar = ScalarType;

        pub fn init(val: Scalar) Self {
            return Self{ .value = val };
        }

        pub fn eq(this: Self, other: Self) bool {
            return this.value == other.value;
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
                prime_power_factors.mul(Other.prime_power_factors),
                float_factors.mul(Other.float_factors),
            );
        }

        pub fn mul(this: Self, other: anytype) Times(@TypeOf(other)) {
            return .{ .value = this.value * other.value };
        }

        pub const Reciprocal = Pow(-1);

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
            return Quantity(Scalar, base_units.pow(power), prime_power_factors.pow(power), float_factors.pow(power));
        }

        pub fn pow(self: Self, power: Fraction) Pow(power) {
            return .{ .value = std.math.pow(self.value, power.toFloat) };
        }

        pub fn ToThe(power: comptime_int) type {
            return Pow(Fraction.fromInt(power));
        }

        pub fn powi(self: Self, power: comptime_int) ToThe(power) {
            return .{ .value = std.math.pow(self.value, power.toFloat) };
        }

        pub fn Root(power: comptime_int) type {
            return Pow(Fraction.init(1, power));
        }

        pub fn root(self: Self, power: comptime_int) ToThe(power) {
            return .{ .value = std.math.pow(self.value, 1.0 / power.toFloat) };
        }
    };
}

pub fn BaseQuantity(name : []const u8, Type : type){
    return Quantity(Type, BaseUnitProduct.fromBase(name), PrimePowerFactors.one, FloatFactors.one);
}

// test "eq" {
//     const F32Meter = Quantity(f32, baseUnit("meter"));
//     const oneMeter = F32Meter.init(1.0);
//     const twoMeters = F32Meter.init(2.0);
//     const oneMeterF16 = Quantity(f32, baseUnit("meter")).init(1.0);

//     try testing.expect(oneMeter.eq(oneMeter));
//     try testing.expect(!oneMeter.eq(twoMeters));
//     try testing.expect(oneMeter.eq(oneMeterF16));
// }

// test "neg" {
//     const F32Meter = Quantity(f32, baseUnit("meter"));
//     const oneMeter = F32Meter.init(1.0);
//     const minusOneMeter = F32Meter.init(-1.0);

//     try testing.expect(oneMeter.neg().eq(minusOneMeter));
// }

// test "add" {
//     const F32Meter = Quantity(f32, baseUnit("meter"));
//     const oneMeter = F32Meter.init(1.0);
//     const twoMeters = Quantity(f16, baseUnit("meter")).init(2.0);
//     const threeMeters = F32Meter.init(3.0);

//     const sum = oneMeter.add(twoMeters);

//     try testing.expect(sum.eq(threeMeters));
//     try testing.expect(@TypeOf(sum) == F32Meter);
// }

// test "sub" {
//     const F32Meter = Quantity(f32, baseUnit("meter"));
//     const oneMeter = F32Meter.init(1.0);
//     const twoMeters = Quantity(f16, baseUnit("meter")).init(2.0);
//     const minusOneMeter = F32Meter.init(-1.0);

//     const difference = oneMeter.sub(twoMeters);

//     try testing.expect(difference.eq(minusOneMeter));
//     try testing.expect(@TypeOf(difference) == F32Meter);
// }

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
