const std = @import("std");
const testing = std.testing;

pub const ComptimeFraction = struct {
    numerator: comptime_int,
    denominator: comptime_int,
    const Self = @This();

    pub fn init(top: comptime_int, bottom: comptime_int) Self {
        return Self{
            .numerator = top,
            .denominator = bottom,
        };
    }

    pub fn eq(self: Self, other: Self) bool {
        return (self.numerator == other.numerator) and (self.denominator == other.denominator);
    }
};

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

const Factor = struct { prime: comptime_int, power: ComptimeFraction };

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
            factorization[i] = .{ .prime = p, .power = ComptimeFraction.init(count, 1) };
            i += 1;
        }
        p += 1;
    }
    return factorization;
}

test "primeFactorization" {
    try testing.expect(primeFactorization(2)[0].power.eq(ComptimeFraction.init(1, 1)));
}
