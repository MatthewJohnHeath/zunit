const std = @import("std");
const testing = std.testing;
const fraction = @import("comptime_fraction.zig");
const Fraction = fraction.ComptimeFraction;

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

fn Factor(BaseType: type) type {
    return struct { base: BaseType, power: Fraction };
}
fn primeFactorization(number: anytype) [distinctPrimeFactorCount(number)]Factor(@TypeOf(number)) {
    const size = distinctPrimeFactorCount(number);
    if (size == 0) {
        return .{};
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
    return factorization;
}

test "primeFactorization" {
    try testing.expect(primeFactorization(1).len == 0);

    const primeFactorsOf2 = primeFactorization(2);
    try testing.expect(primeFactorsOf2.len == 1);
    try testing.expect(primeFactorsOf2[0].base == 2);
    try testing.expect(primeFactorsOf2[0].power.eq(Fraction.fromInt(1)));

    const primeFactorsOf3 = primeFactorization(3);
    try testing.expect(primeFactorsOf3.len == 1);
    try testing.expect(primeFactorsOf3[0].base == 3);
    try testing.expect(primeFactorsOf3[0].power.eq(Fraction.fromInt(1)));

    const primeFactorsOf4 = primeFactorization(3);
    try testing.expect(primeFactorsOf4.len == 1);
    try testing.expect(primeFactorsOf4[0].base == 3);
    try testing.expect(primeFactorsOf4[0].power.eq(Fraction.fromInt(1)));

    const primeFactorsOf6 = primeFactorization(6);
    try testing.expect(primeFactorsOf6.len == 2);
    try testing.expect(primeFactorsOf6[0].base == 2);
    try testing.expect(primeFactorsOf6[0].power.eq(Fraction.fromInt(1)));
    try testing.expect(primeFactorsOf6[1].base == 3);
    try testing.expect(primeFactorsOf6[1].power.eq(Fraction.fromInt(1)));
}

pub fn Factorization(Type: type) type {
    return struct {
        factors: []const Factor(Type),
        const Self = @This();
        pub fn fromInt(n: comptime_int) Self {
            return Self{ .factors = &primeFactorization(n) };
        }
        pub fn eq(comptime self: Self, comptime other: Self) bool {
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

        pub fn reciprocal(self: Self) Self {
            var factors: [self.factors.len]Factor(Type) = undefined;
            for (0..self.factors.len) |i| {
                const factor = self.factors[i];
                factors[i] = Factor(Type){ .base = factor.base, .power = factor.power.neg() };
            }
            return Self{ .factors = &factors };
        }
    };
}

test "Factorization.fromInt" {
    const sixFactorization = Factorization(comptime_int).fromInt(6);
    const primeFactorsOf6 = sixFactorization.factors;
    try testing.expect(primeFactorsOf6.len == 2);
    try testing.expect(primeFactorsOf6[0].base == 2);
    try testing.expect(primeFactorsOf6[0].power.eq(Fraction.fromInt(1)));
    try testing.expect(primeFactorsOf6[1].base == 3);
    try testing.expect(primeFactorsOf6[1].power.eq(Fraction.fromInt(1)));
}

test "Factorization.eq" {
    comptime {
        const sixFactorization = Factorization(comptime_int).fromInt(6);
        try testing.expect(sixFactorization.eq(sixFactorization));
        const tenFactorization = Factorization(comptime_int).fromInt(10);
        try testing.expect(!sixFactorization.eq(tenFactorization));
    }
}

test "Factorization.reciprocal" {
    comptime {
        const sixFactorization = Factorization(comptime_int).fromInt(6);
        const oneSixth = Factorization(comptime_int){
            .factors = &[_]Factor(comptime_int){
                Factor(comptime_int){ .base = 2, .power = Fraction.fromInt(-1) },
                Factor(comptime_int){ .base = 3, .power = Fraction.fromInt(-1) },
            },
        };
        try testing.expect(sixFactorization.reciprocal().eq(oneSixth));
    }
}
