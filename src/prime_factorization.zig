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

const Factor = struct { prime: comptime_int, power: Fraction };
fn primeFactorization(number: comptime_int) [distinctPrimeFactorCount(number)]Factor {
    const size = distinctPrimeFactorCount(number);
    if (size == 0) {
        return .{};
    }

    comptime var factorization: [size]Factor = undefined;
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
            factorization[i] = .{ .prime = p, .power = Fraction.fromInt(count) };
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
    try testing.expect(primeFactorsOf2[0].prime == 2);
    try testing.expect(primeFactorsOf2[0].power.eq(Fraction.fromInt(1)));

    const primeFactorsOf3 = primeFactorization(3);
    try testing.expect(primeFactorsOf3.len == 1);
    try testing.expect(primeFactorsOf3[0].prime == 3);
    try testing.expect(primeFactorsOf3[0].power.eq(Fraction.fromInt(1)));

    const primeFactorsOf4 = primeFactorization(3);
    try testing.expect(primeFactorsOf4.len == 1);
    try testing.expect(primeFactorsOf4[0].prime == 3);
    try testing.expect(primeFactorsOf4[0].power.eq(Fraction.fromInt(1)));

    const primeFactorsOf6 = primeFactorization(6);
    try testing.expect(primeFactorsOf6.len == 2);
    try testing.expect(primeFactorsOf6[0].prime == 2);
    try testing.expect(primeFactorsOf6[0].power.eq(Fraction.fromInt(1)));
    try testing.expect(primeFactorsOf6[1].prime == 3);
    try testing.expect(primeFactorsOf6[1].power.eq(Fraction.fromInt(1)));
}

pub const PrimeFactorization = struct {
    factors: []const Factor,
    const Self = @This();
    pub fn fromInt(n: comptime_int) Self {
        return Self{ .factors = &primeFactorization(n) };
    }
    pub fn eq(comptime self: Self, comptime other: Self) bool {
        if (self.factors.len != other.factors.len) {
            return false;
        }
        for (self.factors, other.factors) |s, o| {
            if (s.prime != o.prime) {
                return false;
            }
            if (!s.power.eq(o.power)) {
                return false;
            }
        }
        return true;
    }
};

test "PrimeFactorization.fromInt" {
    const sixFactorization = PrimeFactorization.fromInt(6);
    const primeFactorsOf6 = sixFactorization.factors;
    try testing.expect(primeFactorsOf6.len == 2);
    try testing.expect(primeFactorsOf6[0].prime == 2);
    try testing.expect(primeFactorsOf6[0].power.eq(Fraction.fromInt(1)));
    try testing.expect(primeFactorsOf6[1].prime == 3);
    try testing.expect(primeFactorsOf6[1].power.eq(Fraction.fromInt(1)));
}
test "PrimeFactorization.eq" {
    const sixFactorization = PrimeFactorization.fromInt(6);
    try testing.expect(sixFactorization.eq(sixFactorization));
    const tenFactorization = PrimeFactorization.fromInt(10);
    try testing.expect(!sixFactorization.eq(tenFactorization));
}
