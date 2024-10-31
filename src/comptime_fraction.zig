const std = @import("std");
const testing = std.testing;

pub const ComptimeFraction = struct {
    numerator: comptime_int,
    denominator: comptime_int,
    const Self = @This();

    pub fn init(top: comptime_int, bottom: comptime_int) Self {
        const divisor = std.math.gcd(@abs(top), @abs(bottom));
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
    
    pub fn isZero(self:Self) bool{
        return self.numerator == 0;
    }

    pub fn fromInt(n: comptime_int) Self {
        return init(n, 1);
    }

    pub fn eq(self: Self, other: Self) bool {
        return (self.numerator == other.numerator) and (self.denominator == other.denominator);
    }


    pub fn neg(self: Self) Self {
        return Self{ .numerator = -self.numerator, .denominator = self.denominator };
    }

    pub fn add(self: Self, other: Self) Self {
        return init(self.numerator * other.denominator + other.numerator * self.denominator, self.denominator * other.denominator);
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

    pub fn toFloat(comptime self: Self) comptime_float {
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

test "fromInt" {
    const five = ComptimeFraction.fromInt(5);
    try testing.expect(five.numerator == 5);
    try testing.expect(five.denominator == 1);
}

test "eq" {
    const half = ComptimeFraction.init(1, 2);
    try testing.expect(half.eq(half));
    const third = ComptimeFraction.init(1, 3);
    try testing.expect(!half.eq(third));
    const one = ComptimeFraction.fromInt(1);
    try testing.expect(one.eq(one));
}

test "neg" {
    const half = ComptimeFraction.init(1, 2);
    const minus_half = ComptimeFraction.init(-1, 2);
    try testing.expect(half.neg().eq(minus_half));
}

test "add" {
    const half = ComptimeFraction.init(1, 2);
    const third = ComptimeFraction.init(1, 3);
    const five_sixths = ComptimeFraction.init(5, 6);

    try testing.expect(half.add(third).eq(five_sixths));

    const minus_third = ComptimeFraction.init(-1, 3);
    const sixth = ComptimeFraction.init(1, 6);

    try testing.expect(half.add(minus_third).eq(sixth));
}

test "sub" {
    const half = ComptimeFraction.init(1, 2);
    const third = ComptimeFraction.init(1, 3);
    const sixth = ComptimeFraction.init(1, 6);

    try testing.expect(half.sub(third).eq(sixth));

    const minus_third = ComptimeFraction.init(-1, 3);
    const five_sixths = ComptimeFraction.init(5, 6);

    try testing.expect(half.sub(minus_third).eq(five_sixths));
    try testing.expect(half.sub(five_sixths).eq(minus_third));
}

test "reciprocal" {
    const two_thirds = ComptimeFraction.init(2, 3);
    const three_halves = ComptimeFraction.init(3, 2);

    try testing.expect(two_thirds.reciprocal().eq(three_halves));
    try testing.expect(three_halves.reciprocal().eq(two_thirds));
}

test "mul" {
    const quarter = ComptimeFraction.init(1, 4);
    const two_thirds = ComptimeFraction.init(2, 3);
    const sixth = ComptimeFraction.init(1, 6);

    try testing.expect(quarter.mul(two_thirds).eq(sixth));
}

test "div" {
    const quarter = ComptimeFraction.init(1, 4);
    const three_halves = ComptimeFraction.init(3, 2);
    const sixth = ComptimeFraction.init(1, 6);

    try testing.expect(quarter.div(three_halves).eq(sixth));
}

test "toFloat" {
    const third = ComptimeFraction.init(1, 3);
    const point_three_recurring: comptime_float = 1.0 / 3.0;
    try testing.expect(third.toFloat() == point_three_recurring);
}
