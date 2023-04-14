module Durations

## We could use Unitful.jl. But it's a bit heavy
## In fact, untits play a minor role, I think.

using MEnums: MEnums
# May want to generate these in a scope
MEnums.@menum Stretch
# We may not need these at all
abstract type Unit end
struct NanoSecond <: Unit end
struct MicroSecond <: Unit end
struct MilliSecond <: Unit end
struct Second <: Unit end

abstract type AbstractDuration end

struct ConstDuration{T,U<:Unit} <: AbstractDuration
    val::T
end

# Times are always in ns
# Do we want to allow Float64 and Int ?
struct Duration{T} <: AbstractDuration
    const_term::T
    stretch_terms::Tuple{Vararg{Stretch}}
    #    stretch_coeff::Tuple{Vararg{Stretch}} We may need coefficents
end

Duration(x::T) where {T<:Real} = Duration{T}(x, tuple())

## TODO: Jet says this is broken. It is probably correct
## But this is not yet tested
# function Base.:+(d1::Duration, d2::Duration)
#     (d1s, d2s) = (d1.stretch_terms, d2.stretch_terms)
#     if all(x -> !any(y -> x in y, d2s), d1s)
#         return Duration(d1.const_term + d2.const_term, (d1s..., d2s...))
#     end
#     return error("not implemented")
# end

end # module Durations
