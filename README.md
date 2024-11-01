# Zunit

This is a library for creating and operating upon floating-point values with units of measure attached: e.g. "8.2 centimetres as a `f32`" or "20.0 seconds as a `comptime_float`

## The rules

- You can add, subtract or compare (only) quantities with the same units.
- You can convert (only) between properties of the same dimensions (e.g. inches to millimetres).
- You can multiply and divide all quantities with ordinary[*](#ordinary_explanation) units. The return type of the operation will be worked out for you.
- You can raise quantities to an arbitrary, rational power providing the power is known at compile time.
- At runtime, values are just floats and operations are just floating point operations.
- You can apply scalar multiples to units to create new units (kilometres and inches from metres, degrees from radians).
- Unexpected type mismatches cannot possibly occur due to floating-point errors on powers, scalar prefixes, etc.
- Normal Zig peer-type resolution applies between scalar types as long as the units are OK.  




<a name="ordinary_explanation">*</a> The exception is properties with an offset from their base unit, like degrees Celsius and Fahrenheit. The maths and physics of multiplying these without first converting them to the base unit is too weird. 