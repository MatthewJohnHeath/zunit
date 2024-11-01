# Zunit

This is a library for creating and operating upon floating-point values with units of measure attached: e.g. "8.2 centimetres as a `f32`" or "20.0 seconds as a `comptime_float`

## The rules

- You can add, subtract or compare (only) quantities with the same units.
```
    const metre = Metre.times(1.0);
    const half_metre = Metre.times(0.5);
    try testing.expect(metre.gt(half_metre));
    try testing.expect(metre.sub(half_metre).eq(half_metre));
```
- You can convert (only) between properties of the same dimensions .
```
    try testing.expect(Byte.time(1.0).convert(Bit.of(f32).eq(Bit.times(8.0)))); 
```
- You can multiply and divide all quantities with ordinary[*](#ordinary_explanation) units. The return type of the operation will be worked out for you.
```   
    const distance = Metre.times(1.25);
    const time = Second.times(0.2);
    const speed = distance.div(time);
    try testing.expect(speed.eq(Metres.Per(Second).times(5.0)));
```
- You can raise quantities to an arbitrary, rational power providing the power is known at compile time.
- At runtime, values are just floats and operations are just floating point operations.
- You can apply scalar multiples to units to create new units (kilometres and furlongs from metres, degrees from radians).
- You can create new base units as needed. 
- Unexpected type mismatches due to floating-point errors on powers, scalar prefixes, etc. ___cannot possibly___ occur. 
- Normal Zig peer-type resolution applies between the scalar types (as long as the units are right).  



<a name="ordinary_explanation">*</a> The exception is properties with an offset from their base unit, like degrees Celsius and Fahrenheit. The maths and physics of multiplying these without first converting them to the base unit is too weird. 