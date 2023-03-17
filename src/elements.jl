"""
    module Elements

Quantum circuit elements. These are enums, that is encoded essentially as integers.
There is a `struct` below `ParamElement` that composes an `Element` with a parameter,
or container of parameters. This is meant to be any kind of parameter, not just an angle.
But it is no meant to carry around metadata that is unrelated to paramaterizing a parametric
gate.
"""
module Elements

using MEnums: MEnums, @menum, @addinblock
using ..Angle: Angle
using ..QuantumDAGs: QuantumDAGs
using ..Interface


export Element, ParamElement
export Q1NoParam, X, Y, Z, H, SX
export Q2NoParam, CX, CY, CZ, CH
export Q1Params1Float, RX, RY, RZ
export Q1Params3Float, U
export QuCl, Measure
export UserNoParam
export IONodes, ClInput, ClOutput, Input, Output
export isinput, isoutput, isquinput, isclinput, isquoutput, iscloutput, isionode

# Elements are ops, input/output, ... everything that lives on a vertex
@menum (Element, blocklength=10^6, numblocks=10, compactshow=true)

@menum OpBlock begin
    Q1NoParam=1
    Q2NoParam
    QNNoParam
    UserNoParam
    Q1Params1Float
    Q1Params2Float
    Q1Params3Float
    QuCl
    IONodes
end

@addinblock Element Q1NoParam I X Y Z H P SX
@addinblock Element Q2NoParam CX CY CZ CH CP
@addinblock Element Q1Params1Float RX RY RZ
@addinblock Element Q1Params3Float U
@addinblock Element QuCl Measure
@addinblock Element IONodes ClInput ClOutput Input Output

# Element with parameters (not Julia parameters, params from the QC domain)
struct ParamElement{ParamsT}
    node::Element
    params::ParamsT
end

Base.:(==)(x::ParamElement, y::ParamElement) = x.node == y.node && x.params == y.params

isquinput(x::Element) = x === Input
isclinput(x::Element) = x === ClInput
isquoutput(x::Element) = x === Output
iscloutput(x::Element) = x === ClOutput

isinput(x::Element) = isquinput(x) || isclinput(x)
isoutput(x::Element) = isquoutput(x) || iscloutput(x)
isionode(x::Element) = isinput(x) || isoutput(x)


# Lexical order, not mathematical
function Base.isless(x::ParamElement, y::ParamElement)
    x.node == y.node || return isless(x.node, y.node)
    return isless(x.params, y.params)
end

# Calling an instance of an `Element` wraps the arguments as parameters.
(element::Element)(param) = ParamElement(element, param)
(element::Element)(params...) = ParamElement(element, params)

Interface.getelement(x::ParamElement) = x.node
Interface.getparams(x::ParamElement) = x.params
Interface.getelement(x::Element) = x
Interface.getparams(x::Element) = nothing

### Angle functions

Angle.normalize_turn(x::ParamElement) = (x.node)(Angle.normalize_turn.(x.params)...)

function Angle.equal_turn(x::ParamElement, y::ParamElement, eqfun = Angle.equal_turn)
    # x === y && return true # Might save time.
    x.node == y.node || return false
    length(x.params) == length(y.params) || return false
    for (px, py) in zip(x.params, y.params)
        eqfun(px, py) || return false
    end
    return true
end

"""
    isapprox_turn(x::ParamElement, y::ParamElement; kw...)


Return `true` if `x` and `y` are approximately equal. The element types must
be equal. `Angle.isapprox_turn` must return `true` element-wise on the parameters.
"""
Angle.isapprox_turn(x::ParamElement, y::ParamElement; kw...) =
    Angle.equal_turn(x, y, (a, b) -> Angle.isapprox_turn(a, b; kw...))

### `rand(X:Z)` works if the following are defined. They probably allow other similar things.
### These methods should be defined as an option in MEnums.jl. But for now, they are here.

const IntT = MEnums.basetype(Element)

Base.convert(::Type{Element}, x::Integer) = Element(x)
Base.convert(::Type{Element}, x::Element) = x
Element(x::Element) = x
Base.zero(::Element) = Element(0)
Base.one(::Element) = Element(1)

for f in (:+, :-, :rem, :div)
    @eval Base.$f(x::Element, y::Element, args...) = Element($f(IntT(x), IntT(y), args...))
    if f === :rem
        @eval Base.$f(x::Element, y::Element, rmode::RoundingMode{:FromZero}, args...) = Element($f(IntT(x), IntT(y), args...))
    end
end

for f in (:*, )
    @eval Base.$f(x::Element, y, args...) = Element($f(IntT(x), y, args...))
    @eval Base.$f(y, x::Element, args...) = Element($f(y, IntT(x), args...))
    @eval Base.$f(y::Element, x::Element, args...) = Element($f(IntT(y), IntT(x), args...))
end

# Element is not an Integer. Julia assumes it is not integer like. That is x / y makes sense, etc.
Base.in(x::Element, r::AbstractRange{Element}) = first(r) <= x <= last(r)

# TODO: We already keep track of largest used index in blocks. We can use them
# To do the following automatically. Eg define range and get `range(Q1NoParam)`.
# const Range_Q1NoParam = X:SX

end # module Elements
