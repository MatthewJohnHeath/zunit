const std = @import("std");
const testing = std.testing;
const fraction = @import("comptime_fraction.zig");

const Fraction = fraction.ComptimeFraction;

pub fn OffsetUnit(AbsoluteUnit: type, offset_by: Fraction) type {
    if (offset_by.isZero()) {
        return AbsoluteUnit;
    }
    return struct {
        const offset_fraction = offset_by;
        pub const offset = AbsoluteUnit.Of(comptime_float).init(offset_by.toFloat());
        pub fn times(val: anytype) Of(@TypeOf(val)) {
            return .{ .value = val };
        }
        const Outer = @This();

        pub fn OffsetBy(amount: Fraction) type {
            return OffsetUnit(AbsoluteUnit, offset_fraction.add(amount));
        }

        pub fn TimesFraction(multiplier: Fraction) type {
            return OffsetUnit(AbsoluteUnit.TimesFraction(fraction), offset_by.div(multiplier));
        }

        pub fn Of(Scalar: type) type {
            return struct {
                value: Scalar,

                const Self = @This();
                const UnitType = Outer;
                pub const Absolute = AbsoluteUnit.Of(Scalar);

                fn init(val: Scalar) Self {
                    return .{ .value = val };
                }

                fn assertSameUnits(other: anytype, comptime function_name: []const u8) void {
                    if (UnitType != @TypeOf(other).UnitType) {
                        @compileError("It is not permitted to call " ++ function_name ++ " except on OffsetUnit types with the same units");
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

                fn TranslatedType(TranslationType: type) type {
                    if (AbsoluteUnit != TranslationType.UnitType) {
                        @compileError("add and sub for OffsetUnit quantities can only be called on quantities of the underlying type.");
                    }
                    const self: Self = undefined;
                    const other: TranslationType = undefined;
                    return Of(@TypeOf(self.value, other.value));
                }

                pub fn add(self: Self, quantity: anytype) TranslatedType(@TypeOf(quantity)) {
                    return .{ .value = self.value + quantity.value };
                }

                pub fn sub(self: Self, quantity: anytype) TranslatedType(@TypeOf(quantity)) {
                    return .{ .value = self.value - quantity.value };
                }

                fn DifferenceType(OtherType: type) type {
                    if (UnitType != OtherType.UnitType) {
                        @compileError("diff can only be called on OffsetUnit types with the same units");
                    }
                    const self: Self = undefined;
                    const other: OtherType = undefined;
                    return AbsoluteUnit.Of(@TypeOf(self.value, other.value));
                }

                pub fn diff(self: Self, other: anytype) DifferenceType(@TypeOf(other)) {
                    return .{ .value = self.value - other.value };
                }

                pub fn toAbsolute(self: Self) Absolute {
                    return Absolute.init(self.value).add(offset);
                }

                pub fn fromAbsolute(in: Absolute) Self {
                    return init(in.value).sub(offset);
                }

                pub fn convert(self: Self, OtherType: type) OtherType {
                    return self.toAbsolute().convert(OtherType);
                }
            };
        }
    };
}

const small_namespace = struct {
    const Outer = @This();
    fn Of(Scalar: type) type {
        return struct {
            value: Scalar,
            const Self = @This();
            const UnitType = Outer;

            fn init(val: Scalar) Self {
               return  .{ .value = val };
            }
            fn convert(self: Self, OtherType: type) OtherType {
                return OtherType.init(self.value);
            }
            fn add(self:Self, other : anytype) Self{
                return .{.value = self.value + other.value};
            }
        };
    }
};

const OffsetUnit32 = OffsetUnit(small_namespace, Fraction.init(1, 2)).Of(f32);
const OffsetUnit64 = OffsetUnit(small_namespace, Fraction.init(1, 2)).Of(f64);

test "eql" {
    try testing.expect(OffsetUnit32.init(2.0).eql(OffsetUnit32.init(2.0)));
    try testing.expect(OffsetUnit32.init(2.0).eql(OffsetUnit64.init(2.0)));
    try testing.expect(!OffsetUnit32.init(2.0).eql(OffsetUnit32.init(1.0)));
    try testing.expect(!OffsetUnit32.init(1.0).eql(OffsetUnit64.init(2.0)));
}

test "neql" {
    try testing.expect(!OffsetUnit32.init(2.0).neql(OffsetUnit32.init(2.0)));
    try testing.expect(!OffsetUnit32.init(2.0).neql(OffsetUnit64.init(2.0)));
    try testing.expect(OffsetUnit32.init(2.0).neql(OffsetUnit32.init(1.0)));
    try testing.expect(OffsetUnit32.init(1.0).neql(OffsetUnit64.init(2.0)));
}

test "lt" {
    try testing.expect(!OffsetUnit32.init(2.0).lt(OffsetUnit32.init(2.0)));
    try testing.expect(!OffsetUnit32.init(2.0).lt(OffsetUnit64.init(2.0)));
    try testing.expect(!OffsetUnit32.init(2.0).lt(OffsetUnit32.init(1.0)));
    try testing.expect(OffsetUnit32.init(1.0).lt(OffsetUnit64.init(2.0)));
}

test "gt" {
    try testing.expect(!OffsetUnit32.init(2.0).gt(OffsetUnit32.init(2.0)));
    try testing.expect(!OffsetUnit32.init(2.0).gt(OffsetUnit64.init(2.0)));
    try testing.expect(OffsetUnit32.init(2.0).gt(OffsetUnit32.init(1.0)));
    try testing.expect(!OffsetUnit32.init(1.0).gt(OffsetUnit64.init(2.0)));
}

test "le" {
    try testing.expect(OffsetUnit32.init(2.0).le(OffsetUnit32.init(2.0)));
    try testing.expect(OffsetUnit32.init(2.0).le(OffsetUnit64.init(2.0)));
    try testing.expect(!OffsetUnit32.init(2.0).le(OffsetUnit32.init(1.0)));
    try testing.expect(OffsetUnit32.init(1.0).le(OffsetUnit64.init(2.0)));
}

test "ge" {
    try testing.expect(OffsetUnit32.init(2.0).ge(OffsetUnit32.init(2.0)));
    try testing.expect(OffsetUnit32.init(2.0).ge(OffsetUnit64.init(2.0)));
    try testing.expect(OffsetUnit32.init(2.0).ge(OffsetUnit32.init(1.0)));
    try testing.expect(!OffsetUnit32.init(1.0).ge(OffsetUnit64.init(2.0)));
}

const AbsoluteUnit64 = small_namespace.Of(f64);

test "add" {
    const offset3 = OffsetUnit32.init(2.0).add(AbsoluteUnit64.init(1.0));
    try testing.expect(offset3.eql(OffsetUnit32.init(3.0)));
    try testing.expect(@TypeOf(offset3) == OffsetUnit64);
}

test "sub" {
    const offset_1 = OffsetUnit32.init(2.0).sub(AbsoluteUnit64.init(1.0));
    try testing.expect(offset_1.eql(OffsetUnit32.init(1.0)));
    try testing.expect(@TypeOf(offset_1) == OffsetUnit64);
}

test "diff" {
    const absolute_1 = OffsetUnit32.init(2.0).diff(OffsetUnit64.init(1.0));
    try testing.expect(absolute_1.value == 1.0);
    try testing.expect(@TypeOf(absolute_1) == AbsoluteUnit64);
}

test "fromAbsolute" {
    const offset_half = OffsetUnit64.fromAbsolute(AbsoluteUnit64.init(1.0));
    try testing.expect(offset_half.value == 0.5);
}

test "toAbsolute" {
    const absolute_1 = OffsetUnit64.init(0.5).toAbsolute();
    try testing.expect(absolute_1.value == 1.0);
}

const smaller_namespace = struct {
    fn Of(Scalar: type) type {
        return struct {
            x: Scalar,
            const Self = @This();

            fn init(val: anytype) Self {
                const x:Scalar = @floatCast(val);
                return .{ .x = x};
            }
        };
    }
};

test "convert" {
    const offset_half = OffsetUnit64.init(0.5);
    const x_one = offset_half.convert(smaller_namespace.Of(f16));
    try testing.expect(x_one.x == 1.0);
}
