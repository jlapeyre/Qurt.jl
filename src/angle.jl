module Angle

export normalize_turn,
    equal_turn,
    isapprox_turn,
    cos_turn,
    sin_turn,
    sincos_turn,
    tan_turn,
    csc_turn,
    sec_turn,
    normalize

export Turn  # normalize will conflict with LinearAlgebra

## I am almost certain we want to measure angles in "turn"s rather than radians.
## But beyond that, what approach?  Do we want to use someting like `Turn` below?
## or UnitfulAngles.jl ?  I think the following few things will are best because
## they are less complicated and don't set off a chain of required
## implementations and modifications

# Testing first if we need to mod is much faster if we don't need it.
"""
    normalize_turn(x)

Return `x` mod `1`.

The return value is in `[0,1)`. Fast exit if `x` is already in this range.
"""
normalize_turn(x) = zero(x) <= x < one(x) ? x : mod(x, one(x))

"""
    cos_turn(x)

Compute the cosine of `x`, an angle measured in "turns".
"""
cos_turn(x) = cospi(2 * x)

"""
    sin_turn(x)

Compute the sine of `x`, an angle measured in "turns".
"""
sin_turn(x) = sinpi(2 * x)


"""
    sincos_turn(x)

Return a `Tuple` of the sine and cosine of `x`, an angle measured in "turns".
"""
sincos_turn(x) = sincospi(2 * x)

# Sometimes this gives more accurate results for example tan_turn
"""
    tan_turn(x)

Compute the tangent of `x`, an angle measured in "turns".
"""
function tan_turn(x)
    (s, c) = sincos_turn(x)
    return s / c
end

for f in (:csc, :sec)  # :tan
    turnf = Symbol(f, :_turn)
    @eval $turnf(x) = $f(2pi * x)
end

"""
    equal_turn(x, y)

Return `true` if `x` and `y` are equal mod 1.

`x` and `y` are intended to be angles measured in "turns".
"""
equal_turn(x, y) = ==(normalize_turn(x), normalize_turn(y))

"""
    isapprox_turn(x, y; kw...)

Return `true` if `x` and `y` are equal mod 1.
"""
isapprox_turn(x, y; kw...) = isapprox(normalize_turn(x), normalize_turn(y); kw...)

### Below here depends on above here, but not vice versa
### Below may or may not be useful.

"""
    Turn{T}

Angular measurement such that one turn around the circle is equal to one.
To convert from radians to `Turn` divide by 2π.
"""
struct Turn{T}
    val::T
end

Base.cos(x::Turn) = cos_turn(x.val)
Base.sin(x::Turn) = sin_turn(x.val)

normalize(x::Turn) = Turn(normalize_turn(x.val))

Base.:(==)(x::Turn, y::Turn) = equal_turn(x.val, y.val)

Base.isapprox(x::Turn, y::Turn; kw...) = isapprox_turn(x.val, y.val; kw...)

# For Turn{Rational}, these operations are so slow that `mod`ing after is not much slower.
for f in (:*, :+, :-, :/)
    @eval Base.$f(x::Turn, y::Turn) = normalize(Turn(($f)(x.val, y.val)))
end

end # module Angle
