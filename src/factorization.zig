const std = @import("std");
const testing = std.testing;
const fraction = @import("comptime_fraction.zig");
const compare = @import("compare.zig");

const NumberCompare = compare.NumberCompare;
const Fraction = fraction.ComptimeFraction;

fn Factor(BaseType: type) type {
    return struct { base: BaseType, power: Fraction };
}

fn Factorization(Type: type, before: fn (lhs: Type, rhs: Type) bool, eq: fn (lhs: Type, rhs: Type) bool) type {
    return struct {
        factors: []const Factor(Type),
        const Self = @This();

        const one = Self{ .factors = &.{} };

        pub fn fromBase(base: Type) Self {
            return .{ .factors = &.{.{ .base = base, .power = Fraction.fromInt(1) }} };
        }

        pub fn eql(comptime self: Self, comptime other: Self) bool {
            if (self.factors.len != other.factors.len) {
                return false;
            }
            for (self.factors, other.factors) |s, o| {
                if (s.base != o.base) {
                    return false;
                }
                if (!s.power.eq(o.power)) {
                    return false;
                }
            }
            return true;
        }

        pub fn isOne(self: Self) bool {
            return self.eql(one);
        }

        fn mulSize(self: Self, other: Self) comptime_int {
            var self_index = 0;
            var other_index = 0;
            var count = 0;
            while (self_index < self.factors.len or other_index < other.factors.len) {
                if (self_index == self.factors.len) {
                    other_index += 1;
                    count += 1;
                } else if (other_index == other.factors.len) {
                    self_index += 1;
                    count += 1;
                } else {
                    const self_base = self.factors[self_index].base;
                    const self_power = self.factors[self_index].power;
                    const other_base = other.factors[other_index].base;
                    const other_power = other.factors[other_index].power;

                    if (eq(self_base, other_base)) {
                        const sum = self_power.add(other_power);
                        if (!sum.eq(Fraction.fromInt(0))) {
                            count += 1;
                        }
                        self_index += 1;
                        other_index += 1;
                    } else if (before(self_base, other_base)) {
                        self_index += 1;
                        count += 1;
                    } else {
                        other_index += 1;
                        count += 1;
                    }
                }
            }
            return count;
        }

        pub fn mul(self: Self, other: Self) Self {
            var factors: [self.mulSize(other)]Factor(Type) = undefined;
            var self_index = 0;
            var other_index = 0;
            var count = 0;
            while (self_index < self.factors.len or other_index < other.factors.len) {
                if (self_index == self.factors.len) {
                    factors[count] = other.factors[other_index];
                    other_index += 1;
                    count += 1;
                } else if (other_index == other.factors.len) {
                    factors[count] = self.factors[self_index];
                    self_index += 1;
                    count += 1;
                } else {
                    const self_base = self.factors[self_index].base;
                    const self_power = self.factors[self_index].power;
                    const other_base = other.factors[other_index].base;
                    const other_power = other.factors[other_index].power;

                    if (eq(self_base, other_base)) {
                        const sum = self_power.add(other_power);
                        if (!sum.eq(Fraction.fromInt(0))) {
                            factors[count] = Factor(Type){ .base = self_base, .power = sum };
                            count += 1;
                        }
                        self_index += 1;
                        other_index += 1;
                    } else if (before(self_base, other_base)) {
                        factors[count] = self.factors[self_index];
                        self_index += 1;
                        count += 1;
                    } else {
                        factors[count] = other.factors[other_index];
                        other_index += 1;
                        count += 1;
                    }
                }
            }
            return Self{ .factors = &factors };
        }

        pub fn reciprocal(self: Self) Self {
            return self.pow(Fraction.fromInt(-1));
        }

        pub fn div(self: Self, other: Self) Self {
            return self.mul(other.reciprocal());
        }

        pub fn pow(self: Self, exponent: Fraction) Self {
            if (exponent.eq(Fraction.fromInt(0))) {
                return Self{ .factors = &.{} };
            }
            const len = self.factors.len;
            var factors: [len]Factor(Type) = undefined;
            for (0..len) |i| {
                factors[i] = .{ .base = self.factors[i].base, .power = self.factors[i].power.mul(exponent) };
            }
            return Self{ .factors = &factors };
        }

        pub fn powi(self: Self, exponent: comptime_int) Self {
            return self.pow(Fraction.fromInt(exponent));
        }

        pub fn root(self: Self, root_power: comptime_int) Self {
            return self.pow(Fraction.fromInt(root_power).reciprocal());
        }
    };
}

pub const ComptimeIntFactorization = Factorization(comptime_int, NumberCompare(comptime_int).before, NumberCompare(comptime_int).eql);
const oneInPrimes = ComptimeIntFactorization{
    .factors = &.{},
};
const twoInPrimes = ComptimeIntFactorization{
    .factors = &.{.{ .base = 2, .power = Fraction.fromInt(1) }},
};
const fiveInPrimes = ComptimeIntFactorization{
    .factors = &.{.{ .base = 5, .power = Fraction.fromInt(1) }},
};
const eightInPrimes = ComptimeIntFactorization{
    .factors = &.{.{ .base = 2, .power = Fraction.fromInt(3) }},
};
const tenInPrimes = ComptimeIntFactorization{
    .factors = &.{ .{ .base = 2, .power = Fraction.fromInt(1) }, .{ .base = 5, .power = Fraction.fromInt(1) } },
};
const oneHundredInPrimes = ComptimeIntFactorization{
    .factors = &.{ .{ .base = 2, .power = Fraction.fromInt(2) }, .{ .base = 5, .power = Fraction.fromInt(2) } },
};
const tenthInPrimes = ComptimeIntFactorization{
    .factors = &.{ .{ .base = 2, .power = Fraction.fromInt(-1) }, .{ .base = 5, .power = Fraction.fromInt(-1) } },
};
const rootTenInPrimes = ComptimeIntFactorization{
    .factors = &.{ .{ .base = 2, .power = Fraction.init(1, 2) }, .{ .base = 5, .power = Fraction.init(1, 2) } },
};
const tenRootTenInPrimes = ComptimeIntFactorization{
    .factors = &.{ .{ .base = 2, .power = Fraction.init(3, 2) }, .{ .base = 5, .power = Fraction.init(3, 2) } },
};

test "Factorization eql" {
    comptime {
        try testing.expect(twoInPrimes.eql(twoInPrimes));
        try testing.expect(!twoInPrimes.eql(tenInPrimes));
    }
}

test "Factorization isOne" {
    comptime {
        try testing.expect(oneInPrimes.isOne());
        try testing.expect(!twoInPrimes.isOne());
    }
}

test "Factorization fromBase" {
    comptime {
        try testing.expect(ComptimeIntFactorization.fromBase(2).eql(twoInPrimes));
    }
}

test "Factorization mul" {
    comptime {
        try testing.expect(twoInPrimes.mul(fiveInPrimes).eql(tenInPrimes));
        try testing.expect(rootTenInPrimes.mul(tenRootTenInPrimes).eql(oneHundredInPrimes));
    }
}

test "Factorization div" {
    comptime {
        try testing.expect(tenInPrimes.div(fiveInPrimes).eql(twoInPrimes));
        try testing.expect(oneHundredInPrimes.div(tenRootTenInPrimes).eql(rootTenInPrimes));
    }
}

test "Factorization reciprocal" {
    comptime {
        try testing.expect(tenInPrimes.reciprocal().eql(tenthInPrimes));
        try testing.expect(tenthInPrimes.reciprocal().eql(tenInPrimes));
    }
}

test "Factorization pow" {
    comptime {
        try testing.expect(tenInPrimes.pow(Fraction.fromInt(2)).eql(oneHundredInPrimes));
        try testing.expect(tenInPrimes.pow(Fraction.fromInt(-1)).eql(tenthInPrimes));
        try testing.expect(tenInPrimes.pow(Fraction.init(1, 2)).eql(rootTenInPrimes));
        try testing.expect(tenRootTenInPrimes.pow(Fraction.init(2, 3)).eql(tenInPrimes));
        try testing.expect(tenInPrimes.pow(Fraction.fromInt(0)).eql(oneInPrimes));
    }
}

test "Factorization powi" {
    comptime {
        try testing.expect(tenInPrimes.powi(2).eql(oneHundredInPrimes));
        try testing.expect(twoInPrimes.powi(3).eql(eightInPrimes));
        try testing.expect(rootTenInPrimes.powi(2).eql(tenInPrimes));
        try testing.expect(tenInPrimes.powi(-1).eql(tenthInPrimes));
        try testing.expect(tenInPrimes.powi(0).eql(oneInPrimes));
    }
}

test "Factorization root" {
    comptime {
        try testing.expect(oneHundredInPrimes.root(2).eql(tenInPrimes));
        try testing.expect(eightInPrimes.root(3).eql(twoInPrimes));
        try testing.expect(tenInPrimes.root(2).eql(rootTenInPrimes));
    }
}

fn distinctPrimeFactorCount(number: comptime_int) comptime_int {
    comptime var remaining = number;
    comptime var count = 0;
    comptime var p = 2;
    while (remaining > 1) {
        if (remaining % p == 0) {
            count += 1;
            while (remaining % p == 0) {
                remaining /= p;
            }
        }
        p += 1;
    }
    return count;
}

test "distinctPrimeFactorCount" {
    try testing.expect(distinctPrimeFactorCount(1) == 0);
    try testing.expect(distinctPrimeFactorCount(2) == 1);
    try testing.expect(distinctPrimeFactorCount(6) == 2);
    try testing.expect(distinctPrimeFactorCount(8) == 1);
    try testing.expect(distinctPrimeFactorCount(12) == 2);
}

pub fn primeFactorization(number: comptime_int) ComptimeIntFactorization {
    const size = distinctPrimeFactorCount(number);
    if (size == 0) {
        return oneInPrimes;
    }

    comptime var factorization: [size]Factor(@TypeOf(number)) = undefined;
    comptime var remaining = number;
    comptime var p = 2;
    comptime var i = 0;
    while (i < size) {
        comptime var count = 0;
        while (remaining % p == 0) {
            remaining /= p;
            count += 1;
        }
        if (count > 0) {
            factorization[i] = .{ .base = p, .power = Fraction.fromInt(count) };
            i += 1;
        }
        p += 1;
    }
    return .{ .factors = &factorization };
}

test "primeFactorization" {
    comptime {
        try testing.expect(primeFactorization(1).eql(oneInPrimes));
        try testing.expect(primeFactorization(2).eql(twoInPrimes));
        try testing.expect(primeFactorization(5).eql(fiveInPrimes));
        try testing.expect(primeFactorization(8).eql(eightInPrimes));
        try testing.expect(primeFactorization(10).eql(tenInPrimes));
        try testing.expect(primeFactorization(100).eql(oneHundredInPrimes));
    }
}

pub fn fractionInPrimes(frac: Fraction) ComptimeIntFactorization {
    return primeFactorization(frac.numerator).div(primeFactorization(frac.denominator));
}

test "fractionInPrimes" {
    comptime {
        try testing.expect(fractionInPrimes(Fraction.init(1, 10)).eql(tenthInPrimes));
    }
}
