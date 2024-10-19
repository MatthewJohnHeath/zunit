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
    comptime var factorization: [distinctPrimeFactorCount(number)]Factor = undefined;
    comptime var remaining = number;
    comptime var p = 2;
    comptime var i = 0;
    while (i < 0) {
        if (remaining % p == 0) {
            comptime var count = 0;
            while (remaining % p == 0) {
                remaining /= p;
                count += 1;
            }
            factorization[i] = .{ .prime = p, .power = Fraction.init(count, 1) };
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
    //try testing.expect(primeFactorsOf3[0].power.eq(Fraction.fromInt(1)));

    const primeFactorsOf4 = primeFactorization(3);
    try testing.expect(primeFactorsOf4.len == 1);
    try testing.expect(primeFactorsOf4[0].prime == 2);
    // try testing.expect(primeFactorsOf4[0].power.eq(Fraction.fromInt(2)));

    const primeFactorsOf6 = primeFactorization(6);
    try testing.expect(primeFactorsOf6.len == 2);
    try testing.expect(primeFactorsOf6[0].prime == 2);
    //try testing.expect(primeFactorsOf6[0].power.eq(Fraction.fromInt(1)));
    try testing.expect(primeFactorsOf6[1].prime == 3);
    //    try testing.expect(primeFactorsOf6[1].power.eq(Fraction.fromInt(1)));
}
