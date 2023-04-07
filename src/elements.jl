"""
    module Elements

Quantum circuit elements. These are enums, that is encoded essentially as integers.
There is a `struct` below `ParamElement` that composes an `Element` with a parameter,
or container of parameters. This is meant to be any kind of parameter, not just an angle.
But it is no meant to carry around metadata that is unrelated to paramaterizing a parametric
gate.
"""
module Elements

using MEnums: MEnums, MEnum, @menum, @addinblock, inblock, ltblock
using ..Angle: Angle
using ..QuantumDAGs: QuantumDAGs
using ..Interface

export Element, ParamElement, WiresElement, WiresParamElement, NoParamElement
export Q1NoParam, I, X, Y, Z, H, SX
export Q2NoParam, CX, CY, CZ, CH
export Q1Params1Float, RX, RY, RZ
export Q1Params3Float, U
export QuCl, Measure
export UserNoParam
export IONodes, ClInput, ClOutput, Input, Output
export isinput,
    isoutput, isquinput, isclinput, isquoutput, iscloutput, isionode, isgate, Paulis

# Elements are ops, input/output, ... everything that lives on a vertex
@menum (Element, blocklength=10^6, numblocks=50, compactshow=true)

@menum OpBlock begin
    Q1NoParam = 1
    Q2NoParam
    QNNoParam
    UserNoParam
    Q1Params1Float
    Q2Params1Float
    Q1Params2Float
    Q1Params3Float
    QuCl
    IONodes
end

@addinblock Element Q1NoParam I X Y Z H P SX
@addinblock Element Q2NoParam CX CY CZ CH CP
@addinblock Element Q1Params1Float RX RY RZ
@addinblock Element Q2Params1Float RZZ
@addinblock Element Q1Params3Float U
# Try putting all quantum gates before all other elements
@addinblock Element QuCl Measure
@addinblock Element IONodes ClInput ClOutput Input Output

const Q1GateBlocks = (Q1NoParam, Q1Params1Float)

# Hmm. what if the op takes varying number of qubits. Like measure
const Q1Blocks = (Q1GateBlocks..., IONodes)
const Q2Blocks = (Q2NoParam, Q2Params1Float)

isgate(x::Element) = MEnums.ltblock(x, QuCl)
const Paulis = (I, X, Y, Z)

function Interface.num_qubits(elem::Element)
    any(block -> inblock(elem, Integer(block)), Q1Blocks) && return 1
    any(block -> inblock(elem, Integer(block)), Q2Blocks) && return 2
    throw(ArgumentError("Unknown or undefined number of qubits"))
end

# Element with parameters (not Julia parameters, params from the QC domain)
struct ParamElement{ParamsT}
    element::Element
    params::ParamsT
end
struct NoParamElement
    element::Element
end

struct WiresElement{WiresT}
    element::Element
    wires::WiresT
end
struct WiresParamElement{WiresT,ParamsT}
    element::Element
    wires::WiresT
    params::ParamsT
end

function Base.:(==)(x::ParamElement, y::ParamElement)
    return x.element == y.element && x.params == y.params
end

isquinput(x::Element) = x === Input
isclinput(x::Element) = x === ClInput
isquoutput(x::Element) = x === Output
iscloutput(x::Element) = x === ClOutput

isinput(x::Element) = isquinput(x) || isclinput(x)
isoutput(x::Element) = isquoutput(x) || iscloutput(x)
isionode(x::Element) = isinput(x) || isoutput(x)

# Lexical order, not mathematical
function Base.isless(x::ParamElement, y::ParamElement)
    x.element == y.element || return isless(x.element, y.element)
    return isless(x.params, y.params)
end

(element::Element)() = NoParamElement(element)
(element::Element)(param) = ParamElement(element, param)
(element::Element)(params...) = ParamElement(element, params)
function (pelement::ParamElement)(wires::Int...)
    return WiresParamElement(pelement.element, wires, pelement.params)
end
(npelement::NoParamElement)(wires::Int...) = WiresElement(npelement.element, wires)

Interface.getelement(x::ParamElement) = x.element
Interface.getparams(x::ParamElement) = x.params
Interface.getelement(x::Element) = x
Interface.getparams(x::Element) = nothing

### Angle functions

Angle.normalize_turn(x::ParamElement) = (x.element)(Angle.normalize_turn.(x.params)...)

function Angle.equal_turn(x::ParamElement, y::ParamElement, eqfun=Angle.equal_turn)
    # x === y && return true # Might save time.
    x.element == y.element || return false
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
function Angle.isapprox_turn(x::ParamElement, y::ParamElement; kw...)
    return Angle.equal_turn(x, y, (a, b) -> Angle.isapprox_turn(a, b; kw...))
end

const IntT = MEnums.basetype(Element)

### `rand(X:Z)` works if the following are defined. They probably allow other similar things.
### These methods should be defined as an option in MEnums.jl. But for now, they are here.
Base.convert(::Type{Element}, x::Integer) = Element(x)
Base.convert(::Type{Element}, x::Element) = x
Element(x::Element) = x
Base.zero(::Element) = Element(0)
Base.one(::Element) = Element(1)

for f in (:+, :-, :rem, :div)
    @eval Base.$f(x::Element, y::Element, args...) = Element($f(IntT(x), IntT(y), args...))
    if f === :rem
        @eval function Base.$f(
            x::Element, y::Element, rmode::RoundingMode{:FromZero}, args...
        )
            return Element($f(IntT(x), IntT(y), args...))
        end
    end
end

for f in (:*,)
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
