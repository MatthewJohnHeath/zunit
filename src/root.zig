const std = @import("std");
const testing = std.testing;
const StructField = std.builtin.Type.StructField;

fn i32Field(comptime fieldName: [:0]const u8) StructField {
    return StructField{
        .name = fieldName,
        .type = i32,
        .default_value = null,
        .is_comptime = false,
        .alignment = 0,
    };
}

test "struct field is something" {
    try testing.expect(i32Field("meter").name[0] == 'm');
}

fn BaseUnitPowerType(comptime name: [:0]const u8) type {
    return @Type(.{
        .Struct = .{
            .layout = std.builtin.Type.ContainerLayout.auto,
            .fields = &[_]StructField{i32Field(name)},
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_tuple = false,
        },
    });
}

test "can make meter power type" {
    try testing.expect(@hasField(BaseUnitPowerType("meter"), "meter"));
}
fn baseUnit(comptime name: [:0]const u8) BaseUnitPowerType(name) {
    comptime var unit: BaseUnitPowerType(name) = undefined;
    @field(unit, name) = 1;
    return unit;
}

test "can make meter" {
    try testing.expect(baseUnit("meter").meter == 1);
}

fn numberOfFieldsInCombined(comptime First: type, comptime Second: type) comptime_int {
    comptime var count = std.meta.fields(Second).len;
    for (std.meta.fields(First)) |field| {
        if (!@hasField(Second, field.name)) {
            count = count + 1;
        }
        return count;
    }
}

test "numberOfFieldsInCombined different" {
    const Meter = BaseUnitPowerType("meter");
    const Second = BaseUnitPowerType("second");
    try testing.expect(numberOfFieldsInCombined(Meter, Second) == 2);
}

test "numberOfFieldsInCombined same" {
    const Meter = BaseUnitPowerType("meter");
    try testing.expect(numberOfFieldsInCombined(Meter, Meter) == 1);
}

fn before(comptime first: []const u8, comptime second: []const u8) bool {
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

test "before" {
    try testing.expect(before("aa", "ab"));
    try testing.expect(!before("ab", "aa"));
    try testing.expect(before("aa", "aaa"));
    try testing.expect(!before("aa", "aa"));
}

fn same(comptime first: []const u8, comptime second: []const u8) bool {
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

test "same" {
    try testing.expect(same("foo", "foo"));
    try testing.expect(!same("foo", "bar"));
    try testing.expect(!same("foo", "foobar"));
    try testing.expect(same("", ""));
    try testing.expect(!same("foo", ""));
}

fn MergeStruct(comptime First: type, comptime Second: type) type {
    comptime var fields_out: [numberOfFieldsInCombined(First, Second)]StructField = undefined;
    const fields_of_first = std.meta.fields(First);
    const fields_of_second = std.meta.fields(Second);
    comptime var first_index = 0;
    comptime var second_index = 0;

    for (0..fields_out.len) |i| {
        if (second_index >= fields_of_second.len) {
            fields_out[i] = fields_of_first[first_index];
            first_index = first_index + 1;
            continue;
        }
        if (first_index >= fields_of_first.len) {
            fields_out[i] = fields_of_second[second_index];
            second_index = second_index + 1;
            continue;
        }

        const first_field = fields_of_first[first_index];
        const first_name = first_field.name;
        const second_field = fields_of_second[second_index];
        const second_name = second_field.name;

        if (same(first_name, second_name)) {
            fields_out[i] = first_field;
            first_index = first_index + 1;
            second_index = second_index + 1;
        } else if (before(first_name, second_name)) {
            fields_out[i] = first_field;
            first_index = first_index + 1;
        } else {
            fields_out[i] = second_field;
            second_index = second_index + 1;
        }
    }

    return @Type(.{ .Struct = .{
        .layout = std.builtin.Type.ContainerLayout.auto,
        .fields = &fields_out,
        .decls = &[_]std.builtin.Type.Declaration{},
        .is_tuple = false,
    } });
}

test "MergeStruct different" {
    const Meter = BaseUnitPowerType("meter");
    const Second = BaseUnitPowerType("second");
    const Combined = MergeStruct(Meter, Second);

    try testing.expect(std.meta.fields(Combined).len == 2);
    try testing.expect(@hasField(Combined, "meter"));
    try testing.expect(@hasField(Combined, "second"));
}

test "MergeStruct same" {
    const Meter = BaseUnitPowerType("meter");
    const Combined = MergeStruct(Meter, Meter);

    try testing.expect(std.meta.fields(Combined).len == 1);
    try testing.expect(@hasField(Combined, "meter"));
}

test "MergeStruct commutes" {
    const Meter = BaseUnitPowerType("meter");
    const Second = BaseUnitPowerType("second");
    const MeterSecond = MergeStruct(Meter, Second);
    const SecondMeter = MergeStruct(Meter, Second);

    try testing.expect(MeterSecond == SecondMeter);
}

fn neededSize(comptime object: anytype) comptime_int {
    comptime var count = 0;
    for (std.meta.fieldNames(@TypeOf(object))) |name| {
        if (@field(object, name) != 0) {
            count = count + 1;
        }
    }
    return count;
}

test "needed size" {
    const MeterSecond = struct {
        meter: comptime_int,
        second: comptime_int,
    };
    const noMetersPerSecond = MeterSecond{
        .meter = 0,
        .second = -1,
    };
    try testing.expect(neededSize(noMetersPerSecond) == 1);
}

fn TrimmedType(comptime object: anytype) type {
    comptime var fields: [neededSize(object)]StructField = undefined;
    comptime var i = 0;
    for(std.meta.fields(@TypeOf(object)))|field|{
        if (@field(object, field.name) != 0){
            fields[i] = field;
            i = i + 1;
        }
    }
    return @Type(.{ .Struct = .{
        .layout = std.builtin.Type.ContainerLayout.auto,
        .fields = &fields,
        .decls = &[_]std.builtin.Type.Declaration{},
        .is_tuple = false,
    } });
}

test "TrimmedType" {
    const MeterSecond = struct {
        meter: comptime_int,
        second: comptime_int,
    };
    const noMetersPerSecond = MeterSecond{
        .meter = 0,
        .second = -1,
    };
    const Trimmed = TrimmedType(noMetersPerSecond);
    try testing.expect(std.meta.fields(Trimmed).len == 1);
    try testing.expect(@hasField(Trimmed, "second"));
}

fn trim(comptime object : anytype) TrimmedType(object){
    const Trimmed =  TrimmedType(object);
    comptime var trimmed:Trimmed = undefined;
    
    for(std.meta.fieldNames(Trimmed))|fieldName|{
            @field(trimmed, fieldName) = @field(object, fieldName);
     }
    return trimmed;
}

test "trim"{
    const MeterSecond = struct {
        meter: comptime_int,
        second: comptime_int,
    };
    const noMetersPerSecond = MeterSecond{
        .meter = 0,
        .second = -1,
    };
    const trimmed = trim(noMetersPerSecond);
    try testing.expect(std.meta.fields(@TypeOf(trimmed)).len == 1);
    try testing.expect(trimmed.second == noMetersPerSecond.second);
}

fn untrimmedMultiply(comptime first: anytype, comptime second : anytype) MergeStruct(@TypeOf(first), @TypeOf(second)){
    const Merged = MergeStruct(@TypeOf(first), @TypeOf(second));
    comptime var merged : Merged = undefined;
    for(std.meta.fieldNames(Merged))|name|{
        @field(merged, name ) = 0;
        if(@hasField(@TypeOf(first), name)){
            @field(merged, name) = @field(first, name);
        }
        if(@hasField(@TypeOf(second), name)){
            @field(merged, name) = @field(merged, name) + @field(second, name);
        }
    }
    return merged;
}

fn multiplyUnits(comptime first: anytype, comptime second : anytype) @TypeOf(trim(untrimmedMultiply(first, second))) {
    return trim(untrimmedMultiply(first, second)) ;
}

test "multiplyUnits" {
    const MeterSecond = struct {
        meter: comptime_int,
        second: comptime_int,
    };
    const metersPerSecond = MeterSecond{
        .meter = 1,
        .second = -1,
    };
    const meterSecond = MeterSecond{
        .meter = 1,
        .second = 1,
    };
    const meterSquare = multiplyUnits(metersPerSecond, meterSecond);

    try testing.expect(std.meta.fields(@TypeOf(meterSquare)).len == 1);
    try testing.expect(meterSquare.meter == 2);
}

fn invertUnit(comptime unit : anytype)@TypeOf(unit){
    const UnitType = @TypeOf(unit);
    comptime var inverted: UnitType = undefined; 
    for(std.meta.fieldNames(UnitType))|name|{
        @field(inverted, name) = -@field(unit, name);
    }
    return inverted;
}

test "invertUnit"{
    const MeterSecond = struct {
        meter: comptime_int,
        second: comptime_int,
    };
    const metersPerSecond = MeterSecond{
        .meter = 1,
        .second = -1,
    };
    const secondsPerMeter = invertUnit(metersPerSecond);
    try testing.expect(secondsPerMeter.meter == -1);
    try testing.expect(secondsPerMeter.second == 1);
}
