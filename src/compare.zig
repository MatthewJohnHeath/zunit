const std = @import("std");
const testing = std.testing;

pub fn NumberCompare(NumberType: type) type {
    return struct {
        pub fn eql(lhs: NumberType, rhs: NumberType) bool {
            return lhs == rhs;
        }

        pub fn before(lhs: NumberType, rhs: NumberType) bool {
            return lhs < rhs;
        }
    };
}

test "NumberCompare eq" {
    const compare = NumberCompare(comptime_int);
    try testing.expect(compare.eql(1, 1));
    try testing.expect(!compare.eql(2, 1));
}

test "NumberCompare before" {
    const compare = NumberCompare(f16);
    try testing.expect(compare.before(1.0, 2.0));
    try testing.expect(!compare.before(1.0, 1.0));
    try testing.expect(!compare.before(2.0, 1.0));
}

pub fn string_eql(first: []const u8, second: []const u8) bool {
    if (first.len != second.len) {
        return false;
    }

    for (first, second) |f, s| {
        if (f != s) {
            return false;
        }
    }
    return true;
}

test "string_eql" {
    try testing.expect(string_eql("aa", "aa"));
    try testing.expect(string_eql("", ""));
    try testing.expect(!string_eql("aa", "ab"));
    try testing.expect(!string_eql("a", "aa"));
    try testing.expect(!string_eql("", "aa"));
    try testing.expect(!string_eql("ab", "aa"));
}

pub fn string_before(first: []const u8, second: []const u8) bool {
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

test "string_compare before" {
    try testing.expect(string_before("aa", "ab"));
    try testing.expect(string_before("a", "aa"));
    try testing.expect(string_before("", "aa"));
    try testing.expect(!string_before("ab", "aa"));
    try testing.expect(!string_before("aa", "aa"));
}
