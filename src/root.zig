const std = @import("std");
const testing = std.testing;
const StructField = std.builtin.Type.StructField;


fn i32Field(comptime fieldName:[:0]const u8) StructField{
     return StructField{
        .name = fieldName,
        .type = i32,
        .default_value = null,
        .is_comptime = false,
        .alignment = 0,
    };
}

test "struct field is something"{
    try testing.expect(i32Field("meter").name[0] == 'm');
}

fn BaseUnitPowerType(comptime name: [:0]const u8) type{
    return @Type(.{
        .Struct = .{
            .layout = std.builtin.Type.ContainerLayout.auto,
            .fields = &[_] StructField{i32Field(name)},
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_tuple = false,
        },
    });
 }

test "can make meter power type"{
    try testing.expect(@hasField(BaseUnitPowerType("meter"), "meter"));
}
 fn baseUnit(comptime name: [:0]const u8) BaseUnitPowerType(name){
    comptime var unit:BaseUnitPowerType(name) = undefined;
    @field(unit, name) = 1;
    return unit;
 }

test "can make meter"{
    try testing.expect(baseUnit("meter").meter == 1);
}

fn numberOfFieldsInCombined(comptime First : type, comptime Second : type) comptime_int{
    comptime var count = std.meta.fields(Second).len;
        for(std.meta.fields(First)) |field|{
        if(!@hasField(Second, field.name)){
            count = count + 1;
        }
        return count;
    }
}

test "numberOfFieldsInCombined different"{
    const Meter  = BaseUnitPowerType("meter");
    const Second = BaseUnitPowerType("second");
    try testing.expect(numberOfFieldsInCombined(Meter, Second) == 2);
}

test "numberOfFieldsInCombined same"{
    const Meter  = BaseUnitPowerType("meter");
    try testing.expect(numberOfFieldsInCombined(Meter, Meter) == 1);
}

fn MergeStruct(comptime First : type, comptime Second : type) type {
    comptime var fields: [numberOfFieldsInCombined(First, Second)]StructField = undefined;
    
    for(std.meta.fields(First), 0..) |field, i|{
        fields[i] = field;
    }

    comptime var i = std.meta.fields(First).len;

    for(std.meta.fields(Second))|field|{
        if(!@hasField(First, field.name)){
            fields[i] = field;
            i = i + 1;
        }
    }
    
    return @Type(.{
        .Struct = .{
            .layout = std.builtin.Type.ContainerLayout.auto,
            .fields = &fields,
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_tuple = false,
        }
    });
}

test "MergeStruct different"{
    const Meter  = BaseUnitPowerType("meter");
    const Second = BaseUnitPowerType("second");
    const Combined = MergeStruct(Meter, Second);

    try testing.expect(std.meta.fields(Combined).len == 2);
    try testing.expect(@hasField(Combined, "meter"));
    try testing.expect(@hasField(Combined, "second"));
}

test "MergeStruct same"{
    const Meter  = BaseUnitPowerType("meter");
    const Combined = MergeStruct(Meter, Meter);

    try testing.expect(std.meta.fields(Combined).len == 1);
    try testing.expect(@hasField(Combined, "meter"));
}
