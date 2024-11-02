# Zunit

This is a library for creating and operating upon floating-point values with units of measure attached: e.g. "8.2 centimetres as a `f32`" or "20.0 seconds as a `comptime_float`

## The rules

- You can add, subtract or compare (only) quantities with the same units.
```
    try testing.expect(metres(1.0).gt(metres(-1.0)));
    try testing.expect(pixel(0.5).sub(pixel(0.5)).eq(pixel(0.5)));
```
- You can convert (only) between properties of the same dimensions .
```
    try testing.expect(bytes(1.0).convert(Bit.of(f32).eq(bits(8.0)))); 
```
- You can multiply and divide all quantities with ordinary[*](#ordinary_explanation) units. The return type of the operation will be worked out for you.
```   
    const speed = metres(1.25).div(seconds(0.2));
    try testing.expect(speed.eq(Metres.Per(Second).times(5.0)));
```
- You can raise quantities to an arbitrary, rational power providing the power is known at compile time.
- At runtime, values are just floats and operations are just floating point operations.
- You can apply scalar multiples to units to create new units (e.g. kilometres or furlongs from metres, degrees from radians).
- You can create new base units as needed. 
```
    const Iguana = BaseUnit("iguana");
    const rate_of_iguanas = Iguana.Per(Second).times(2.0);
```
- Normal Zig peer-type resolution should apply between the scalar types (as long as the units are right).  
```   
    try testing.expect(Second.Of(f32).init(1.0).eq(Second.Of(f64).init(1.0)));
```
- Unexpected type mismatches due to floating-point errors on powers, scalar prefixes, etc. ***cannot possibly*** occur. 

----------------
<a name="ordinary_explanation">*</a> The exception is properties with an offset from their base unit, like degrees Celsius and Fahrenheit. The maths and physics of multiplying these without first converting them to the base unit is too weird. 