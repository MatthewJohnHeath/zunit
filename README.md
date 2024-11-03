# Zunit

This is a library for creating and operating upon floating-point values with units of measure attached: e.g. "8.2 centimetres as a `f32`" or "20.0 seconds as a `comptime_float`.

Its aims are: 
1. Catch errors in dimensions or units at compile time.
2. Never have unexpected type mismatches due to floating point errors.
3. Have expected "Zig-like" behaviour: peer-type resolution for scalar types and no hidden conversions. 

## The rules

- You can add, subtract or compare (only) quantities with the same units.
```zig
    try testing.expect(metres(1.0).gt(metres(-1.0)));
    try testing.expect(pixels(1.0).sub(pixels(0.5)).eql(pixels(0.5)));
    //will not compile if below is uncommented
    //try testing.expect(metres(1.0).gt(pixels(-1.0)));
    //try testing.expect(metres(1.0).lt(inches(1.0))); 
```
- You can convert (only) between properties of the same dimensions .
```zig
    try testing.expect(bytes(1.0).convert(Bit.Of(f32).eql(bits(8.0)))); 
    // Will not compile if the following isi uncommented
    //try testing.expect(bytes(1.0).convert(Mole.Of(f32)).eql(moles(8.0))); 
```
- You can multiply and divide all quantities with ordinary[*](#ordinary_explanation) units by other such quantities and by floats. The return type of the operation will be worked out for you.
```zig   
    const speed = metres(1.25).div(seconds(0.25));
    try testing.expect(speed.eql(Metre.Per(Second).times(5.0)));
    try testing.expect(speed.mul(2.0).eql(Metre.Per(Second).times(10.0)));
```
- You can raise quantities to an arbitrary, rational power providing the power is known at compile time.
```zig
    try testing.expect(Metre.Of(f32).init(2.0).powi(3).eql(Metre.ToThe(3).times(8.0)));
    try testing.expect(Second.Of(f32).init(4.0).root(2).eql(Second.Root(2).times(2.0)));
```
- At runtime, values are just floats and operations are just floating point operations.
- You can apply scalar multiples to units to create new units (e.g. kilometres or furlongs from metres, degrees from radians).
```zig
pub const Rot = Radian.Times(FloatPrefix(2.0 * std.math.pi));
pub const rot = Rot.times;
pub const Degree = Rot.Times(IntPrefix(360).Reciprocal);
pub const degrees = Degree.times;

test "degrees" {
    const epsilon = 0.0000001;
    try testing.expect(std.math.approxEqAbs(f32, degrees(180.0).convert(Radian.Of(f32)).value, std.math.pi, epsilon));
}
```
- You can create new base units as needed. 
```zig
    const Iguana = BaseUnit("iguana");
    const rate_of_iguanas = Iguana.times(1.0).div(seconds(0.5));
    try testing.expect(rate_of_iguanas.eql(Iguana.Per(Second).times(2.0)));
```
- Normal Zig peer-type resolution should apply between the scalar types (as long as the units are right).  
```zig   
    try testing.expect(Metre.Of(f16).init(2.0).eql(Metre.Of(f64).init(2.0)));
```
- Unexpected type mismatches due to floating-point errors on powers, scalar prefixes, etc. ***cannot possibly*** occur. 

----------------
<a name="ordinary_explanation">*</a> The exception is properties with an offset from their base unit, like degrees Celsius and Fahrenheit. The maths and physics of multiplying these without first converting them to the base unit is too weird. 