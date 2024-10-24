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


fn NumberCompare(NumberType:type) type {
    return struct{
        fn eql(lhs : NumberType, rhs : NumberType) bool{
            return lhs == rhs;
        }

        fn before(lhs : NumberType, rhs : NumberType) bool{
            return lhs < rhs;
        }
    };
}

test "NumberCompare eq" {
    const compare = NumberCompare(comptime_int);
    try testing.expect(compare.eql(1,1));
    try testing.expect(!compare.eql(2,1));
}

test "NumberCompare before" {
    const compare = NumberCompare(f16);
    try testing.expect(compare.before(1.0,2.0));
    try testing.expect(!compare.before(1.0,1.0));
    try testing.expect(!compare.before(2.0,1.0));
}

const string_compare = struct{
    fn eql( first: []const u8,  second: []const u8) bool {
        if(first.len != second.len){
            return false;
        }
        
        for (first, second) |f, s| {
            if (f != s) {
                return false;
            }
        }
        return true;
    }

    fn before( first: []const u8,  second: []const u8) bool {
        const smaller_length = @min(first.len, second.len);
        for (first[0..smaller_length], second[0..smaller_length]) |f, s| {
            if (f < s) {
                return true;
            }
            if (s < f) {
                return false;
            }
        }
        return first.len < second.len;
    }

};

test "string_compare eql"{
    try testing.expect(string_compare.eql("aa","aa"));
    try testing.expect(string_compare.eql("",""));
    try testing.expect(!string_compare.eql("aa","ab"));
    try testing.expect(!string_compare.eql("a","aa"));
    try testing.expect(!string_compare.eql("","aa"));
    try testing.expect(!string_compare.eql("ab","aa"));
}

test "string_compare before"{
    try testing.expect(string_compare.before("aa","ab"));
    try testing.expect(string_compare.before("a","aa"));
    try testing.expect(string_compare.before("","aa"));
    try testing.expect(!string_compare.before("ab","aa"));
    try testing.expect(!string_compare.before("aa","aa"));
}


pub fn Factorization(Type: type, before: fn (lhs: Type, rhs: Type) bool, eq: fn (lhs: Type, rhs: Type) bool) type {
    return struct {
        factors: []const Factor(Type),
        const Self = @This();
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

        fn mulSize(self: Self, other: Self) comptime_int{
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

        fn div(self: Self, other: Self) Self {
            return self.mul(other.reciprocal());
        }

        fn pow(self:Self, exponent: Fraction)Self{
            if(exponent.eq(Fraction.fromInt(0))){
                return Self{.factors = &[]Factor(Type)};
            }
            const len = self.factors.len;
            var factors : [len]Factor(Type) = undefined;
            for(0..len)|i|{
                factors[i] = .{.base = self.factors[i].base, .power = self.factors[i].power.mul(exponent)};
            }
            return Self{.factors = &factors};
        } 

    };
}

const ComptimeIntFactorization 
    = Factorization(comptime_int, NumberCompare(comptime_int).before, NumberCompare(comptime_int).eql);
const oneInPrimes = ComptimeIntFactorization{
    .factors = &.{},
};
const twoInPrimes = ComptimeIntFactorization{
    .factors = &.{.{.base = 2, .power = Fraction.fromInt(1)}},
};
const fiveInPrimes = ComptimeIntFactorization{
    .factors = &.{.{.base = 5, .power = Fraction.fromInt(1)}},
};
const tenInPrimes = ComptimeIntFactorization{
    .factors = &.{.{.base = 2, .power = Fraction.fromInt(1)}, .{.base = 5, .power = Fraction.fromInt(1)}},
};
const oneHundredInPrimes = ComptimeIntFactorization{
    .factors = &.{.{.base = 2, .power = Fraction.fromInt(2)},  .{.base = 5, .power = Fraction.fromInt(2)}},
};
const tenthInPrimes = ComptimeIntFactorization{
    .factors = &.{.{.base = 2, .power = Fraction.fromInt(-1)}, .{.base = 5, .power =Fraction.fromInt(-1)}},
};
const rootTenInPrimes = ComptimeIntFactorization{
    .factors = &.{.{.base = 2, .power = Fraction.init(1,2)}, .{.base = 5, .power = Fraction.init(1,2)}},
};
const tenRootTenInPrimes = ComptimeIntFactorization{
    .factors = &.{.{.base = 2, .power = Fraction.init(3,2)}, .{.base = 5, .power = Fraction.init(3,2)}},
};

test "Factorization eql" {
    comptime{
        try testing.expect(twoInPrimes.eql(twoInPrimes));
        try testing.expect(!twoInPrimes.eql(tenInPrimes));
    }
}

test "Factorization mul" {
    comptime{
        try testing.expect(twoInPrimes.mul(fiveInPrimes).eql(tenInPrimes));
        try testing.expect(rootTenInPrimes.mul(tenRootTenInPrimes).eql(oneHundredInPrimes));
    }
}

test "Factorization div" {
    comptime{
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
        try testing.expect(tenInPrimes.pow(Fraction.init(1,2)).eql(rootTenInPrimes));
        try testing.expect(tenRootTenInPrimes.pow(Fraction.init(2,3)).eql(tenInPrimes));
    }
}
// test "Factorization.fromInt" {
//     const sixFactorization = Factorization(comptime_int).fromInt(6);
//     const primeFactorsOf6 = sixFactorization.factors;
//     try testing.expect(primeFactorsOf6.len == 2);
//     try testing.expect(primeFactorsOf6[0].base == 2);
//     try testing.expect(primeFactorsOf6[0].power.eq(Fraction.fromInt(1)));
//     try testing.expect(primeFactorsOf6[1].base == 3);
//     try testing.expect(primeFactorsOf6[1].power.eq(Fraction.fromInt(1)));
// }