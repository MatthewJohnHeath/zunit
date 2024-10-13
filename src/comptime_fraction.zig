const std = @import("std");
const testing = std.testing;

fn gcd(first: comptime_int, second: comptime_int) comptime_int {
    comptime var a = @abs(first);
    comptime var b = @abs(second);
    while (a != 0) {
        const temp = a;
        a = b % a;
        b = temp;
    }
    return b;
}

test "gcd" {
    try testing.expect(gcd(6, 4) == 2);
    try testing.expect(gcd(6, -5) == 1);
    try testing.expect(gcd(-6, -5) == 1);
}

const ComptimeFraction = struct {
    numerator: comptime_int,
    denominator: comptime_int,
    const Self = @This();

    pub fn init(top: comptime_int, bottom: comptime_int) Self {
        const divisor = gcd(top, bottom);
        comptime var numerator = top / divisor;
        comptime var denominator = bottom / divisor;
        if (denominator < 0) {
            denominator = -denominator;
            numerator = -numerator;
        }
        return Self{
            .numerator = numerator,
            .denominator = denominator,
        };
    }

    pub fn eq(self: Self, other: Self) bool {
        return self.numerator == other.numerator and self.denominator == other.denominator;
    }

    pub fn neg(self: Self) Self {
        return Self{ .numerator = -self.numerator, .denominator = self.denominator };
    }

    pub fn add(self: Self, other: Self) Self {
        return init(self.numerator * other.denominator + other.numerator * self.deonominator, self.denominator * other.denominator);
    }

    pub fn sub(self: Self, other: Self) Self {
        return self.add(other.neg());
    }

    pub fn reciprocal(self: Self) Self {
        if (self.numerator >= 0) {
            return Self{ .numerator = self.denominator, .denominator = self.numerator };
        } else {
            return Self{ .numerator = -self.denominator, .denominator = -self.numerator };
        }
    }

    pub fn mul(self: Self, other: Self) Self {
        return init(self.numerator * other.numerator, self.denominator * other.denominator);
    }

    pub fn div(self: Self, other: Self) Self {
        return self.mul(other.reciprocal());
    }

    pub fn to_float(comptime self: Self) comptime_float {
        const numerator: comptime_float = @floatFromInt(self.numerator);
        const denominator: comptime_float = @floatFromInt(self.denominator);
        return numerator / denominator;
    }
};

test "init" {
    const half = ComptimeFraction.init(1, 2);
    try testing.expect(half.numerator == 1);
    try testing.expect(half.denominator == 2);

    const third = ComptimeFraction.init(4, 12);
    try testing.expect(third.numerator == 1);
    try testing.expect(third.denominator == 3);

    const quarter = ComptimeFraction.init(-3, -12);
    try testing.expect(quarter.numerator == 1);
    try testing.expect(quarter.denominator == 4);

    const minus_half = ComptimeFraction.init(1 << 10, -1 << 11);
    try testing.expect(minus_half.numerator == -1);
    try testing.expect(minus_half.denominator == 2);
}
